//
//  NTARemoteViewController.m
//  NTARemote
//
//  Created by Sam on 07.07.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "NTARemoteViewController.h"
#include <stdio.h>

@implementation NTARemoteViewController

@synthesize 
	incLabel, 
	headingLabel, 
	calibratingSpin, 
	calibrateButton, 
	speedLabel, 
	flipButton, 
	loadingView, 
	loadingLabel, 
	connected, 
	dontConnect;

lo_address txAddr;
NSUserDefaults *defaults;
CLLocationManager *locationManager;
UIActionSheet *nodesListSheet, *setNorthSheet;

- (void)viewDidLoad {
	defaults = [NSUserDefaults standardUserDefaults];
	self.connected = 0;
	if(![defaults floatForKey:@"Speed"])
		[defaults setFloat:5 forKey:@"Speed"];
	
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:kUpdateFrequency];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	
	locationManager = [[CLLocationManager alloc] init];
	
	flipView = [[FlipView alloc] initWithNibName:@"FlipView" bundle:[NSBundle mainBundle]];
	instructionsView = [[InfoView alloc] initWithNibName:@"InfoView" bundle:[NSBundle mainBundle]];

	postureName = [[NSString alloc] init];
	
	
}


- (void)viewWillAppear:(BOOL)animated {
	
	screenMode = [defaults boolForKey:@"ScreenMode"];
	NSLog(@"viewWillAppear");
	self.dontConnect = 0;
	NSLog(@"connected = %d", self.connected);
	
	if(!screenMode && locationManager.headingAvailable) {
		NSLog(@"compass is available");
		locationManager.delegate = self;
		locationManager.headingFilter = 0.1;
		[locationManager startUpdatingHeading];
	}
	
	if(self.connected == 0)
		[self getSockets];
	else
		[self sendData];
}



- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	float orientationY = (0-acceleration.y*90)-calY;
	currentInclination = orientationY;
	
	self.incLabel.text = [NSString stringWithFormat:@"%d", (int)orientationY];
	
	if(flatCalibration) {
		collectedSamples++;
		totalY+=orientationY;
		
		if(collectedSamples == kCalibrationSamples) {
			flatCalibration = NO;
			calY = totalY/collectedSamples;
			[self.calibratingSpin stopAnimating];
			self.calibrateButton.hidden = NO;
		}		
	}

}


- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	currentHeading = (int)newHeading.magneticHeading-calO;
	
	if(currentHeading < 0)
		currentHeading = 360+currentHeading;
	
	else if(currentHeading > 360)
		currentHeading = currentHeading-360;
	
	headingLabel.text = [NSString stringWithFormat:@"%d", currentHeading];
}


- (void)promptSetNorth {
	setNorthSheet = [[UIActionSheet alloc] 
					 initWithTitle:@"Point the device towards the base's north"  
					 delegate:self 
					 cancelButtonTitle:nil  
					 destructiveButtonTitle:nil 
					 otherButtonTitles:@"Set North", nil];
	
	[setNorthSheet showInView:self.view];
	[setNorthSheet release];
}


- (IBAction)promptActions {
	UIActionSheet *actionsMessage = [[UIActionSheet alloc] 
								  initWithTitle:nil 
								  delegate:self 
								  cancelButtonTitle:@"Cancel" 
								  destructiveButtonTitle:nil 
								  otherButtonTitles:@"Set North", @"Set Horizon", @"Reset Position", nil];
	
	[actionsMessage showInView:self.view];
	[actionsMessage release];
	
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if(self.connected == 1) {
		UITouch *touch = [[touches allObjects] lastObject];
		CGPoint fPosition = [touch locationInView:self.view];
		
		float posY = ((-240+fPosition.y)/-2.40)/100;
		float speedFloat;

		speedFloat = pow(posY,3)*[defaults floatForKey:@"Speed"];
		currentSpeed = speedFloat;
		speedLabel.text = [NSString stringWithFormat:@"%.1f", speedFloat];
		
		if(screenMode) {
			float posX = ((-160+fPosition.x)/-1.60)/100;
			currentFakeOrientation = posX*0.15;
		}
	}
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if(self.connected == 1) {
		speedLabel.text = @"0";
		NSLog(@"touchedEnded");
		currentSpeed = 0;
		currentFakeOrientation = 0;
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
	
	if(actionSheet == nodesListSheet)
		[self gotNode:[actionSheet buttonTitleAtIndex:buttonIndex]];
	
	else if(actionSheet == setNorthSheet || buttonIndex == 0) {
		calO = currentHeading+calO;
		headingLabel.text = [NSString stringWithFormat:@"0"];
		NSLog(@"0");
	}
	
	else if(buttonIndex == 1) {
		self.calibrateButton.hidden = YES;
		[self.calibratingSpin startAnimating];
		
		flatCalibration = YES;
		totalY = 0;
		collectedSamples = 0;
		NSLog(@"1");
	}
	
	else if(buttonIndex == 2) {
		NSString *string = [NSString stringWithFormat:@"/SPIN/default/%@", postureName];
		const char *path = [string UTF8String];
		lo_send(txAddr, path, "sfff", "setTranslation", 0.0, 0.0, 1.5);
		NSLog(@"2");
	}
	
}


- (IBAction)showFlip {
	self.dontConnect = 1;
	[locationManager stopUpdatingHeading];
	
	flipView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:flipView animated:YES];
}

- (IBAction)showInstructions {
	[self presentModalViewController:instructionsView animated:YES];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [super dealloc];
}


#pragma mark Sockets:


int nodelist_handler(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data) {
	int i;
	
	printf("path: <%s>\n", path);
	for (i=0; i<argc; i++) {
		printf("arg %d '%c' ", i, types[i]);
		lo_arg_pp(types[i], argv[i]);
		printf("\n");
	}
	printf("\n");
	
	NTARemoteViewController *self = (NTARemoteViewController*)user_data;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *argOne = [NSString stringWithUTF8String:(char*)argv[1]];
	self.connected = 1;
	NSLog(@"connected");
	
	if([argOne compare:@"UserNode"] == NSOrderedSame) {
		
		if(argc <= 2)
			[self performSelectorOnMainThread:@selector(gotNode:) withObject:[NSString stringWithUTF8String:(char*)argv[i]] waitUntilDone:YES];
		
		else {
			nodesListSheet = [[UIActionSheet alloc] 
									 initWithTitle:@"Select the PostureBase you are about to use"  
									 delegate:self 
									 cancelButtonTitle:nil 
									 destructiveButtonTitle:nil 
									 otherButtonTitles:nil];
			
			for(int i=2; i < argc; i++)
				[nodesListSheet performSelectorOnMainThread:@selector(addButtonWithTitle:) withObject:[NSString stringWithUTF8String:(char*)argv[i]] waitUntilDone:YES];
			
			[nodesListSheet performSelectorOnMainThread:@selector(showInView:) withObject:self.view waitUntilDone:YES];
		}
	}
	
	[pool release];
	NSLog(@"nodelist handler");
	
	return 0;
}


int socket_handler(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data) {
	NTARemoteViewController *self = (NTARemoteViewController*)user_data;
	
    if(self.connected == 0 && self.dontConnect == 0) {
		
		char *ip = (char*)argv[1];
		int port = lo_hires_val('i', argv[2]);
		
		const char *tPath = (char*)argv[0];
		const char *tIp = (char*)argv[3];
		int tPort = lo_hires_val('i', argv[4]);
		
		char path[50];
		sprintf(path, "/SPIN/%s", tPath);
		
		char portString[7];
		sprintf(portString, "%d", tPort);
		
		lo_server_thread tServer = lo_server_thread_new_multicast(tIp, portString, NULL);
		lo_server_thread_add_method(tServer, path, NULL, nodelist_handler, self);
		lo_server_thread_start(tServer);
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSString stringWithUTF8String:ip], @"IP",
							   [NSNumber numberWithInt:port], @"Port", 
							   [NSString stringWithUTF8String:path], @"Path",
								nil];

		
		[self performSelectorOnMainThread:@selector(setupSocketWithArgs:) withObject:aDict waitUntilDone:YES];
		
		[pool release];
		
		//fflush(stdout);		
	}
	
	
	return 1;
}


- (void)notConnected {
	if(self.connected == 0) {
		self.view.userInteractionEnabled = NO;
		[self.loadingView setHidden:YES];
		[offlineView setHidden:NO];
	}
}

- (IBAction)getSockets {
	[self performSelector:@selector(notConnected) withObject:nil afterDelay:7];
	
	[self.loadingView setHidden:NO];
	[offlineView setHidden:YES];
	self.view.userInteractionEnabled = NO;
	lo_server_thread server = lo_server_thread_new_multicast("224.0.0.1", "54320", NULL);
	
	if(server != nil) {
		lo_server_thread_add_method(server, "/ping/SPIN", "ssisii", socket_handler, self);
		lo_server_thread_start(server);
	}
}



- (void)setupSocketWithArgs:(NSDictionary*)args {
	
	const char *ip = [[args valueForKey:@"IP"] UTF8String];
	const char *path = [[args valueForKey:@"Path"] UTF8String];
	int port = [[args objectForKey:@"Port"] intValue];
	
	char portString[10];
	sprintf(portString, "%d", [[args objectForKey:@"Port"] intValue]);

	txAddr = lo_address_new(ip, portString);
	lo_send(txAddr, path, "ss", "getNodeList", "*");
	
	NSLog(@"setupSocketWithIP:%s onPort:%d", ip, port);
	
//	NSString *pathString = [NSMutableString stringWithFormat:@"/SPIN/default/%@", [defaults stringForKey:@"Client"]];
//	const char *path = [pathString UTF8String];
//	lo_send(txAddr, path, "siii", "setOrientation", 0, 0, 0);
}



- (void)gotNode:(NSString*)pName {
	[self.loadingView setHidden:YES];
	self.view.userInteractionEnabled = YES;
	[self sendData];
	postureName = pName;
	[self promptSetNorth];
}


- (void)sendData {
	
	float osX, osY, osZ;
	float speedX, speedY, speedZ;
	
	
	speedZ = currentSpeed*sin(currentInclination*PI/180);
	NSString *string = [NSString stringWithFormat:@"/SPIN/default/%@", postureName];
	const char *path = [string UTF8String];
	
	if(!screenMode) {
		speedX = currentSpeed*sin(currentHeading*PI/180)*cos(currentInclination*PI/180);
		speedY = currentSpeed*cos(currentHeading*PI/180)*cos(currentInclination*PI/180);
		
		if(speedX != pSpeedX || speedY != pSpeedY || speedZ != pSpeedZ) {
			lo_send(txAddr, path, "sfff", "setVelocity", speedX, speedY, speedZ);
			pSpeedX = speedX;
			pSpeedY = speedY;
			pSpeedZ = speedZ;
			NSLog(@"%f, %f, %f", speedX, speedY, speedZ);
		}
	}
	
	else {
		speedX = 0;
		speedY = currentSpeed*cos(currentInclination*PI/180);
		
		if(osX != speedX || osY != speedY || osZ != speedZ) {
			lo_send(txAddr, path, "sfff", "setVelocity", speedX, speedY, speedZ);
			lo_send(txAddr, path, "siif", "rotate", 0, 0, currentFakeOrientation);
		}
	}
	
	//NSLog(@"sending data to %@", string);
	
	osX = speedX;
	osY = speedY;
	osZ = speedZ;
	
	if(self.dontConnect == 0)
		[self performSelector:@selector(sendData) withObject:nil afterDelay:kDataPushFrequency];
}

- (void)disconnect {
	lo_address_free(txAddr);
	self.connected = 0;
	NSLog(@"disconnect");
}

@end
