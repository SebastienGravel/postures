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
	dontConnect,
	menuEnabled,
	postureName,
	currentSpeed,
	motionManager;

lo_address txAddr;
NSUserDefaults *defaults;
CLLocationManager *locationManager;
UIActionSheet *nodesListSheet, *setNorthSheet;

- (void)viewDidLoad {
	defaults = [NSUserDefaults standardUserDefaults];
	self.connected = 0;
	//if(![defaults floatForKey:@"Speed"])
		[defaults setFloat:20 forKey:@"Speed"];
	
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:kUpdateFrequency];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	
	locationManager = [[CLLocationManager alloc] init];
	
	flipView = [[FlipView alloc] initWithNibName:@"FlipView" bundle:[NSBundle mainBundle]];
	instructionsView = [[InfoView alloc] initWithNibName:@"InfoView" bundle:[NSBundle mainBundle]];

	postureName = [[NSString alloc] init];
	
	
	// SETUP MOTION MANAGER:
	NSLog(@"deviceMotionAvailable? %d", motionManager.deviceMotionAvailable);
	
	motionManager = [[CMMotionManager alloc] init];
	
	//BOOL motionEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"motionEnabled"];
	BOOL motionEnabled = YES;
	NSLog(@"default motionEnabled: %d", motionEnabled);
	[self setMotionEnabled:motionEnabled];
	
	//zeroAttitude = [[NSUserDefaults standardUserDefaults] objectForKey:@"zeroAttitude"];
	
	//motionManager.deviceMotionUpdateInterval = 1.0/60.0; // 60Hz = 16.6667ms
	//motionManager.deviceMotionUpdateInterval = 1.0/50.0; // 50Hz = 20ms
	//motionManager.deviceMotionUpdateInterval = 1.0/40.0; // 40Hz = 25ms
	//motionManager.deviceMotionUpdateInterval = 1.0/30.0; // 30Hz = 33.333ms
	//motionManager.deviceMotionUpdateInterval = 1.0/15.0; // 15Hz = 66.67ms
	motionManager.deviceMotionUpdateInterval = 1.0/10.0; // 10Hz = 100ms
	//motionManager.deviceMotionUpdateInterval = 1.0/4.00; //  4Hz = 250ms
	
	/*
	//NSLog(@"initial motionManager rate: %d hz", (int)motionManager.deviceMotionUpdateInterval);
	//NSTimeInterval t = motionManager.deviceMotionUpdateInterval;
	//NSLog(@"initial motionManager rate: %@", (int)t*60);
	
	int hz = [[NSUserDefaults standardUserDefaults] integerForKey:@"motionRate"];
	NSLog(@"stored update rate: %d hz", hz);
	if (hz > 0) [self setMotionRate:hz];
	else [self setMotionRate:40];
	*/
	NSLog(@"motionManager rate: %f sec", motionManager.deviceMotionUpdateInterval);
	
}
/*
- (void)applicationWillEnterForeground:(UIApplication *)application {
	
	NSLog(@"applicationWillEnterForeground");
	
	[self disconnect];
	self.dontConnect = 0;


 //   [self.view reloadInputViews];
	[self viewWillAppear:TRUE];
}
*/


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
	
	//self.incLabel.text = [NSString stringWithFormat:@"%d", (int)orientationY];
	
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
	
	//headingLabel.text = [NSString stringWithFormat:@"%d", currentHeading];
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
	
	
	
	
	NSString *string = [NSString stringWithFormat:@"/SPIN/default/%@-target", postureName];
	const char *path = [string UTF8String];
	lo_send(txAddr, path, "ss", "setParent", [postureName UTF8String]);
	lo_send(txAddr, path, "ssi", "setEnabled", [[NSString stringWithFormat:@"%@-target-instructions", postureName] UTF8String], 1);	
	
	
	UIActionSheet *actionsMessage = [[UIActionSheet alloc] 
								  initWithTitle:@"Point at the calibration target on the screen, and click 'Calibrate'" 
								  delegate:self 
								  cancelButtonTitle:@"Cancel" 
								  destructiveButtonTitle:nil 
								  otherButtonTitles:@"Calibrate", nil];
							      //otherButtonTitles:@"Set North", @"Set Horizon", @"Reset Position", nil];
	
	[actionsMessage showInView:self.view];
	[actionsMessage release];
	
}

- (void) speedScale:(NSTimer *)timer
{
	//if (fabs(speedScaleValue) < 5) speedScaleValue += (float)[timer userInfo];	

	// While we maintain a currentSpeed of 90% of our max speed, increment a 
	// scale value over time. This is multiplied by the currentSpeed just before
	// sending:
	if (fabs(currentSpeed) > 0.6 * [defaults floatForKey:@"Speed"])
		speedScaleValue += 0.1;
	else
		speedScaleValue -= 0.5;

	// ensure speedScaleValue doesn't go below one or above a max scale value:
	if (speedScaleValue < 1) speedScaleValue = 1.0;
	else if (speedScaleValue > 5) speedScaleValue = 5.0;
	
	
	
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	speedScaleValue = 1.0;
	
	if(self.connected == 1) {
		UITouch *touch = [[touches allObjects] lastObject];
		startTouch = [touch locationInView:self.view];

		speedScaleTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5
													   target: self
													 selector: @selector(speedScale:)
													 userInfo: nil
													  repeats: YES];
	}	
	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if(self.connected == 1) {
		UITouch *touch = [[touches allObjects] lastObject];
		CGPoint fPosition = [touch locationInView:self.view];
		
		//float posY = ((-240+fPosition.y)/-2.40)/100;
		float posY = ((-237.5+fPosition.y+5.5)/-2.375)/100; // weird coords from touch; range=[-5.5,469.5]
		currentSpeed = pow(posY,3) * [defaults floatForKey:@"Speed"];

		//NSLog(@"fPosition=%f, posY=%f, currentSpeed=%f, speedScaleValue=%f", fPosition.y, posY, currentSpeed, speedScaleValue);
		
		if(screenMode) {
			float posX = ((-160+fPosition.x)/-1.60)/100;
			currentFakeOrientation = posX*0.15;
		}
	}
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if (self.connected == 1) {
		
		[speedScaleTimer invalidate];
		
		UITouch *touch = [[touches allObjects] lastObject];
		
		if (menuEnabled)
		{
			NSUInteger numTaps = [touch tapCount];
			NSLog(@"numTaps= %d", numTaps);
			if (numTaps>0)
			{
				lo_send(txAddr, "/SPIN/default/menu", "s", "select");
			}
			else
			{
				CGPoint endTouch = [touch locationInView:self.view];
				
				if (startTouch.x+startTouch.y < endTouch.x+endTouch.y)
					lo_send(txAddr, "/SPIN/default/menu", "s", "highlightNext");
				else
					lo_send(txAddr, "/SPIN/default/menu", "s", "highlightPrev");
			}

		}
		
		else
		{
			
			speedLabel.text = @"0";
			NSLog(@"touchedEnded");
			currentSpeed = 0;
			speedScaleValue = 1.0;
			currentFakeOrientation = 0;
		}
	}
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
	if (actionSheet != nodesListSheet)
	{
		NSString *string = [NSString stringWithFormat:@"/SPIN/default/%@-target", postureName];
		const char *path = [string UTF8String];
		lo_send(txAddr, path, "ss", "setParent", [[NSString stringWithFormat:@"%@-pointer", postureName] UTF8String]);	
		lo_send(txAddr, path, "ssi", "setEnabled", [[NSString stringWithFormat:@"%@-target-instructions", postureName] UTF8String], 0);	
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex < 0) return; //[self actionSheetCancel:actionSheet];
	
	if (actionSheet == nodesListSheet)
	{
		[self gotNode:[actionSheet buttonTitleAtIndex:buttonIndex]];
	}
	
	else
	{
		// this is the calibration actionsheet
		
		if (buttonIndex == 0)
		{
			[self setMotionZero:self];
			
			//calO = currentHeading+calO;
			//headingLabel.text = [NSString stringWithFormat:@"0"];
			NSLog(@"Recalibrated");
		
			[self actionSheetCancel:actionSheet];
			/*
			NSString *string = [NSString stringWithFormat:@"/SPIN/default/%@-target", postureName];
			const char *path = [string UTF8String];
			lo_send(txAddr, path, "ss", "setParent", [[NSString stringWithFormat:@"%@-pointer", postureName] UTF8String]);
			lo_send(txAddr, path, "ssi", "setEnabled", [[NSString stringWithFormat:@"%@-target-instructions", postureName] UTF8String], 0);	
			*/
		}
		
		else {
			// cancelled:
			[self actionSheetCancel:actionSheet];
		}
	}
		
	// OLD (start calibrating zenith/pitch):
	/*
		self.calibrateButton.hidden = YES;
		[self.calibratingSpin startAnimating];
		
		flatCalibration = YES;
		totalY = 0;
		collectedSamples = 0;
	}
	*/
	
}

- (IBAction)resetPosition
{	
	if (self.connected == 1)
	{
		NSString *string = [NSString stringWithFormat:@"/SPIN/default/%@", postureName];
		const char *path = [string UTF8String];
		lo_send(txAddr, path, "sfff", "setTranslation", 0.0, 0.0, 1.5);
		lo_send(txAddr, path, "ss", "event", "reset");

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
	
	
	/*
	printf("path: <%s>\n", path);
	for (i=0; i<argc; i++) {
		printf("arg %d '%c' ", i, types[i]);
		lo_arg_pp(types[i], argv[i]);
		printf("\n");
	}
	printf("\n");
	*/
	 
	NTARemoteViewController *self = (NTARemoteViewController*)user_data;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	

	if (argc>2)
	{
		
		NSString *argOne = [NSString stringWithUTF8String:(char*)argv[1]];
		self.connected = 1;
		
		if([argOne compare:@"UserNode"] == NSOrderedSame) {
			
			if(argc <= 2)
			{
				
				//[self performSelectorOnMainThread:@selector(gotNode:) withObject:[NSString stringWithUTF8String:(char*)argv[i]] waitUntilDone:YES];
			}
				
			else {
				
				if (nodesListSheet) [nodesListSheet dismissWithClickedButtonIndex:-1 animated:NO];
				
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
		
	}
	
	[pool release];
	
	return 0;
}


int menu_handler(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data)
{
	/*
	int i;
	printf("path: <%s>\n", path);
	for (i=0; i<argc; i++) {
		printf("arg %d '%c' ", i, types[i]);
		lo_arg_pp(types[i], argv[i]);
		printf("\n");
	}
	printf("\n");
	*/
	
	NTARemoteViewController *self = (NTARemoteViewController*)user_data;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (argc>=2)
	{
		
		NSString *argOne = [NSString stringWithUTF8String:(char*)argv[0]];
		if([argOne compare:@"setEnabled"] == NSOrderedSame)
		{
			self.menuEnabled = (BOOL)lo_hires_val(types[1], argv[1]);
			lo_send(txAddr, [[NSString stringWithFormat:@"/SPIN/default/%@", self.postureName] UTF8String], "sfff", "setVelocity", 0.0, 0.0, 0.0);
			self.currentSpeed = 0;
		}
	}
	
	[pool release];
	return 0;
}


int socket_handler(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data) {
	NTARemoteViewController *self = (NTARemoteViewController*)user_data;
	
    if ((self.connected == 0) && (self.dontConnect == 0)) {
		
		char *ip = (char*)argv[1];
		int port = lo_hires_val('i', argv[2]);
		
		const char *tPath = (char*)argv[0];
		const char *tIp = (char*)argv[4];
		int tPort = lo_hires_val('i', argv[5]);
		
		char path[50];
		sprintf(path, "/SPIN/%s", tPath);
		
		char portString[7];
		sprintf(portString, "%d", tPort);
		
		lo_server_thread tServer = lo_server_thread_new_multicast(tIp, portString, NULL);
		lo_server_thread_add_method(tServer, path, NULL, nodelist_handler, self);
		lo_server_thread_add_method(tServer, [[NSString stringWithFormat:@"/SPIN/%s/menu", tPath] UTF8String], NULL, menu_handler, self);
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
		self.dontConnect = 0;
		self.view.userInteractionEnabled = NO;
		[self.loadingView setHidden:YES];
		[offlineView setHidden:NO];
	}
}

- (IBAction)getSockets {
	[self performSelector:@selector(notConnected) withObject:nil afterDelay:10];
	
	[self.loadingView setHidden:NO];
	[offlineView setHidden:YES];
	self.view.userInteractionEnabled = NO;
	lo_server_thread server = lo_server_thread_new_multicast("239.0.0.1", "54320", NULL);
	
	if(server != nil) {
		lo_server_thread_add_method(server, "/SPIN/__server__", "ssiisii", socket_handler, self);
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
	lo_send(txAddr, path, "ss", "getNodeList", "UserNode");
	
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
	//[self promptSetNorth];
}


- (void)sendData {
	
	return;
	
	if (!menuEnabled)
	{
		
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
	
	}
	
	if(self.dontConnect == 0)
		[self performSelector:@selector(sendData) withObject:nil afterDelay:kDataPushFrequency];
}

- (void)disconnect {
	lo_address_free(txAddr);
	self.connected = 0;
	NSLog(@"disconnect");
}



-(void) setMotionRate:(int)hz
{
	motionManager.deviceMotionUpdateInterval = 1.0/hz;
	[[NSUserDefaults standardUserDefaults] setInteger:hz forKey:@"motionRate"];
	NSLog(@"motionManager now set to update at %d hz", (int) motionManager.deviceMotionUpdateInterval);
}

-(BOOL) setMotionEnabled:(BOOL)enable
{
	if (enable && !motionManager.deviceMotionActive)
	{
		// start the motionManager
		
		CMDeviceMotionHandler motionHandler = ^(CMDeviceMotion *mData, NSError *error)
		{
			if (zeroAttitude) [mData.attitude multiplyByInverseOfAttitude:zeroAttitude];
			
			double y = sin(-mData.attitude.pitch + 1.570796326795) * cos(-mData.attitude.yaw);
			double x = sin(-mData.attitude.pitch + 1.570796326795) * sin(-mData.attitude.yaw);
			double z = cos(-mData.attitude.pitch + 1.570796326795);
			double pitch = mData.attitude.pitch*57.2957795;
			double yaw =   mData.attitude.yaw*57.2957795;
			
			speedLabel.text = [NSString stringWithFormat:@"%.1f", currentSpeed * speedScaleValue];
			headingLabel.text = [NSString stringWithFormat:@"%.1f", yaw];
			incLabel.text = [NSString stringWithFormat:@"%.1f", pitch];
			
			/*
			NSLog(@"orientation: [%f, %f, %f], dirVector: [%f, %f, %f], speed=%f, speedScale=%f",
				  mData.attitude.pitch,
				  mData.attitude.roll,
				  mData.attitude.yaw,
				  x,
				  y,
				  z,
				  currentSpeed, speedScaleValue);
			//NSLog(@"quat = [%f, %f, %f]", mData.attitude.quaternion.x, mData.attitude.quaternion.y, mData.attitude.quaternion.z, mData.attitude.quaternion.w);	
			 */
			
			if (txAddr)
			{
				
				 //lo_send(lo_addr, [sweeperOSCpath UTF8String], "sffff",
				/*
				 lo_send(txAddr, [[NSString stringWithFormat:@"/SPIN/default/%@-pointer", postureName] UTF8String], "sffff",
						 "setOrientationQuat",
						 mData.attitude.quaternion.x,
						 mData.attitude.quaternion.y,
						 mData.attitude.quaternion.z,
						 mData.attitude.quaternion.w);
				 */
				
				lo_send(txAddr, [[NSString stringWithFormat:@"/SPIN/default/%@-pointer", postureName] UTF8String], "sfff",
						"setOrientation", pitch, 0.0, yaw);

				if (!menuEnabled)
					lo_send(txAddr, [[NSString stringWithFormat:@"/SPIN/default/%@", postureName] UTF8String], "sfff",
							"setVelocity",
							currentSpeed * speedScaleValue * x,
							currentSpeed * speedScaleValue * y,
							currentSpeed * speedScaleValue * z
							);

			}
		};
		
		[motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:motionHandler];
	}
	else if (!enable && motionManager.deviceMotionActive)
	{
		[motionManager stopDeviceMotionUpdates];
	}
	[[NSUserDefaults standardUserDefaults] setBool:enable forKey:@"motionEnabled"];
	
	NSLog(@"motionManager enabled? %d", [motionManager isDeviceMotionActive]);
	
	return [motionManager isDeviceMotionActive];
}

- (void) setMotionZero:(id)sender
{
	[zeroAttitude release];
	zeroAttitude = [motionManager.deviceMotion.attitude copy];
	//[[NSUserDefaults standardUserDefaults] setObject:zeroAttitude forKey:@"zeroAttitude"];
}

@end
