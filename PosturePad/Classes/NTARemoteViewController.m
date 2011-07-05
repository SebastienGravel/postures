//
//  NTARemoteViewController.m
//  NTARemote
//
//  Created by Sam on 07.07.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "NTARemoteViewController.h"
#import "Reachability.h"
#include <stdio.h>

@implementation NTARemoteViewController

@synthesize 
	incLabel, 
	headingLabel, 
	calibratingSpin, 
	calibrateButton, 
	speedLabel, 
	loadingView, 
	loadingLabel, 
	connected, 
	ignoreInfoMessages,
	menuEnabled,
	postureName,
    serverName,
	currentSpeed,
	minAccel,
	maxAccel,
	pitch,
	yaw,
	motionMode,
	motionManager;

lo_address udpAddr;
lo_address tcpAddr;
lo_server_thread infoServer;
NSUserDefaults *defaults;
CLLocationManager *locationManager;
UIActionSheet *nodesListSheet, *setNorthSheet;

- (void)viewDidLoad
{
	connected = NO;
    calibrating = NO;
    infoServer = 0;

	defaults = [NSUserDefaults standardUserDefaults];
	[defaults setFloat:20 forKey:@"Speed"];
	
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:kUpdateFrequency];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	
	locationManager = [[CLLocationManager alloc] init];
	
	postureName = [[NSString alloc] init];
    serverName = @"default";
	
	
	// SETUP MOTION MANAGER:
	
	motionManager = [[CMMotionManager alloc] init];
	locationManager.delegate = self;
	
	
	if (motionManager.deviceMotionAvailable)
	{
		motionMode = MOTION_MANAGER;
		NSLog(@"Using motion manager (with gyro) for orientation");
		
		[self setMotionEnabled:YES];
		
		updateRate = 1.0/10.0; // 10Hz = 100ms
		motionManager.deviceMotionUpdateInterval = updateRate;
		
		NSLog(@"motionManager rate: %f sec", motionManager.deviceMotionUpdateInterval);
		
		
	}
	else if ([CLLocationManager headingAvailable])
	{
		motionMode = LOCATION_MANAGER;
		NSLog(@"Using location manager (compass only) for heading");
		locationManager.headingFilter = 0.1;
		[locationManager startUpdatingHeading];
		updateRate = kDataPushFrequency;
	}
	else {
		motionMode = DISABLED;
	}
	
	minAccel = 0;
	maxAccel = 0;
	userHolding = YES;
	[self checkAccumAccel];
    
}
/*
- (void)applicationWillEnterForeground:(UIApplication *)application {
	
	NSLog(@"applicationWillEnterForeground");
	
	[self disconnect];
	self.ignoreInfoMessages = 0;


 //   [self.view reloadInputViews];
	[self viewWillAppear:TRUE];
}
*/


- (void)viewWillAppear:(BOOL)animated
{
	NSLog(@"viewWillAppear: connected = %d", self.connected);

	NetworkStatus wifiStatus = [[Reachability sharedReachability] localWiFiConnectionStatus];
    NSLog(@"network status = %d", wifiStatus);
    
    /*
    // Use the Reachability class to determine if the internet can be reached.
    [[Reachability sharedReachability] setHostName:@"http://www.google.com"];
    
    // Set Reachability class to notifiy app when the network status changes.
    //[[Reachability sharedReachability] setNetworkStatusNotificationsEnabled:YES];
    //Set a method to be called when a notification is sent.
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:@"kNetworkReachabilityChangedNotification" object:nil];
    
    NetworkStatus remoteHostStatus = [[Reachability sharedReachability] remoteHostStatus];
    NetworkStatus internetConnectionStatus = [[Reachability sharedReachability] internetConnectionStatus];
    
    NSLog(@"remote status = %d, internet status = %d", remoteHostStatus, internetConnectionStatus);
    */
    
    //if (internetConnectionStatus == NotReachable || remoteHostStatus == NotReachable)
    if (wifiStatus == NotReachable)
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Network Status"
                              message:@"A wifi connection is required. Please connect to the local Posture network and try again."
                              delegate:self
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK",
                              nil];
        alert.tag = 404;
        [alert show];
    }
    else
    {
        //self.ignoreInfoMessages = 0;	
        [self connect];
    }
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex 
{
	if (alert.tag==404)
	{
        // probably shouldn't do this (according to apple):
        //exit(0);
    }
}


- (void)connect
{
/*
    NSLog(@"discoveryDisabled? %d, serverName=%@, addr=%@ servUDP=%@, serverTCP=%@, user=%@",
          [defaults boolForKey:@"disableDiscovery"],
          [defaults stringForKey:@"serverName"],
          [defaults stringForKey:@"serverAddr"],
          [defaults stringForKey:@"serverUdp"],
          [defaults stringForKey:@"serverTcp"],
          [defaults stringForKey:@"userID"]);
*/  
    
    if ([defaults boolForKey:@"disableDiscovery"])
    {
        [self stopInfoHandler];
        
        serverName = [defaults stringForKey:@"serverName"];
        postureName = [defaults stringForKey:@"userID"];
        
        lo_address_free(udpAddr);
        lo_address_free(tcpAddr);
        udpAddr = lo_address_new([[defaults stringForKey:@"serverAddr"] UTF8String], [[defaults stringForKey:@"serverUdp"] UTF8String]);
        tcpAddr = lo_address_new_with_proto(LO_TCP, [[defaults stringForKey:@"serverAddr"] UTF8String], [[defaults stringForKey:@"serverTcp"] UTF8String]);
        
        NSLog(@"Sending to manual address: %s", lo_address_get_url(udpAddr));
        NSLog(@"Sending to manual address: %s", lo_address_get_url(tcpAddr));
        
        connected = YES;
    }
    
    else
    {
        // Discovery mode just starts the info handler, which waits for messages
        // from the server. When a server comes online, a nodelist handler will
        // be started to listen for UserNodes from SPIN. Everytime a new user
        // is connected, an actionsheet will be presented, allowing us to select
        // the posture UserNode to control. Once selected, the gotNode method is
        // called, and the connected flag is set to true.
        [self startInfoHandler];
    }
    

    // start sending data:
    sendDataTimer = [NSTimer scheduledTimerWithTimeInterval:updateRate
                                                     target:self
                                                   selector:@selector(sendData)
                                                   userInfo:nil
                                                    repeats:YES];
}

- (void) disconnect
{
    // stop sending data
    if ((sendDataTimer) && ([sendDataTimer isValid]))
    {
        [sendDataTimer invalidate];
        sendDataTimer = nil;
    }
    
    // stop the info handler (if there is one):
    [self stopInfoHandler];
    
	lo_address_free(udpAddr);
	lo_address_free(tcpAddr);
    
	connected = NO;
	NSLog(@"disconnected");
}


- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
	if (motionMode == LOCATION_MANAGER)
	{
		pitch = ((0-acceleration.y*90)-calY);
		
		if (flatCalibration)
		{
			collectedSamples++;
			totalY += ((0-acceleration.y*90)-calY);
			
			if (collectedSamples == kCalibrationSamples)
			{
				flatCalibration = NO;
				calY = totalY/collectedSamples;
				[self.calibratingSpin stopAnimating];
				//self.calibrateButton.hidden = NO;
			}
		}
	}
	
	//accumAccel += sqrt((acceleration.x*acceleration.x) + (acceleration.y*acceleration.y) + (acceleration.z*acceleration.z));
	//accumAccel += fabs(acceleration.z);
	
	if (acceleration.z < minAccel) minAccel = acceleration.z;
	if (acceleration.z > maxAccel) maxAccel = acceleration.z;
	
	/*
	NSLog(@"accel=%f,%f,%f  mag=%f  accumAccel=%f", acceleration.x, acceleration.y, acceleration.z,
		  sqrt((acceleration.x*acceleration.x) + (acceleration.y*acceleration.y) + (acceleration.z*acceleration.z)),
		  accumAccel); 
	*/
}

- (void)checkAccumAccel
{
	//NSLog(@"minAccel=%f, maxAccel=%f, diff=%f", minAccel, maxAccel, (maxAccel-minAccel));
	
	float delta = maxAccel - minAccel;
	if (delta > 0.03)
	{
        //NSLog(@"delta >0.03, userHolding=%d, disableRecalibration=%d", userHolding, [defaults boolForKey:@"disableRecalibration"]);
		if ((userHolding==NO) && (![defaults boolForKey:@"disableRecalibration"]))
		{
			[self promptActions];
			userHolding = YES;
		}			
	}
	else if (delta < 0.015)
	{
		// if it is really still, we start checking more frequently for movement
		if (userHolding)
		{
			if (calibrateActionSheet) [calibrateActionSheet dismissWithClickedButtonIndex:-1 animated:NO];
		}		
		userHolding = NO;
	}
	
	
	minAccel = 99;
	maxAccel = -99;
	[self performSelector:@selector(checkAccumAccel) withObject:nil afterDelay:3];

}


- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
	if (motionMode == LOCATION_MANAGER)
	{
		yaw = -(newHeading.magneticHeading-calO) + 90.0;
		
		if (yaw < 0) yaw = yaw + (2.0 * PI);
		else if (yaw > 2*PI) yaw = yaw -  (2.0 * PI);
	}
}


- (void)promptSetNorth
{
	setNorthSheet = [[UIActionSheet alloc] 
					 initWithTitle:@"Point the device towards the base's north"  
					 delegate:self 
					 cancelButtonTitle:nil  
					 destructiveButtonTitle:nil 
					 otherButtonTitles:@"Set North", nil];
	
	[setNorthSheet showInView:self.view];
	[setNorthSheet release];
}


- (IBAction)promptActions
{
	if (!connected) return;
		
	NSString *string = [NSString stringWithFormat:@"/SPIN/%@/%@-target", serverName, postureName];
	const char *path = [string UTF8String];
	//lo_send(tcpAddr, path, "ss", "setParent", [postureName UTF8String]);
	lo_send(tcpAddr, path, "ssi", "setEnabled", [[NSString stringWithFormat:@"%@-target-instructions", postureName] UTF8String], 1);	
	lo_send(tcpAddr, [[NSString stringWithFormat:@"/SPIN/%@/%@-pointer", serverName, postureName] UTF8String], "sfff", "setOrientation", -7.0, 0.0, 0.0);
    
	if (calibrateActionSheet) [calibrateActionSheet dismissWithClickedButtonIndex:-1 animated:NO];
	
	calibrateActionSheet = [[UIActionSheet alloc] 
								  initWithTitle:@"Point at the calibration target on the screen, and click 'Calibrate'" 
								  delegate:self 
								  cancelButtonTitle:@"Cancel" 
								  destructiveButtonTitle:nil 
								  otherButtonTitles:@"Calibrate", nil];
							      //otherButtonTitles:@"Set North", @"Set Horizon", @"Reset Position", nil];
	
    calibrating = YES;
	[calibrateActionSheet showInView:self.view];
	//[calibrateActionSheet release];
    //calibrateActionSheet = nil;
	
}

- (void) speedScale:(NSTimer *)timer
{
	//if (fabs(speedScaleValue) < 5) speedScaleValue += (float)[timer userInfo];	

    /*
	// While we maintain a currentSpeed of 90% of our max speed, increment a 
	// scale value over time. This is multiplied by the currentSpeed just before
	// sending:
    
	if (fabs(currentSpeed) > 0.6 * [defaults floatForKey:@"Speed"])
		speedScaleValue += 0.1;
	else
		speedScaleValue -= 0.5;
    */
    
    
    // start speedscaling when finger is at top or bottom edge
    if ((currentTouchY>0.75)||(currentTouchY<-0.75))
        speedScaleValue += 0.1;
    else
        speedScaleValue -= 0.5;
    
    
	// ensure speedScaleValue doesn't go below one or above a max scale value:
	if (speedScaleValue < 1) speedScaleValue = 1.0;
	else if (speedScaleValue > 5) speedScaleValue = 5.0;
}

- (void) startSpeedScale
{
    if (![speedScaleTimer isValid])
    {
        //NSLog(@"startSpeedScale");
        speedScaleValue = 1.0;
        speedScaleTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5
													   target: self
													 selector: @selector(speedScale:)
													 userInfo: nil
                                                      repeats: YES];
    }
}

- (void) stopSpeedScale
{
    //if ((speedScaleTimer) && ([speedScaleTimer isValid]))
    if (speedScaleTimer)
    {
        //NSLog(@"stopSpeedScale");
        [speedScaleTimer invalidate];
        speedScaleTimer = nil;
        speedScaleValue = 1.0;
    }
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (connected)
    {
		UITouch *touch = [[touches allObjects] lastObject];
		startTouch = [touch locationInView:self.view];
        
        // start speedScaleTimer
        [self startSpeedScale];
	}		
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (connected)
	{
		UITouch *touch = [[touches allObjects] lastObject];
		CGPoint fPosition = [touch locationInView:self.view];
		
		//float posY = ((-240+fPosition.y)/-2.40)/100;
		currentTouchY = ((-237.5+fPosition.y+5.5)/-2.375)/100; // weird coords from touch; range=[-5.5,469.5]
		currentSpeed = pow(currentTouchY,3) * [defaults floatForKey:@"Speed"];


        
		//NSLog(@"fPosition=%f, posY=%f, currentSpeed=%f, speedScaleValue=%f", fPosition.y, currentTouchY, currentSpeed, speedScaleValue);
	}
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{	
    [self stopSpeedScale];
    
	if (connected)
    {
		
		UITouch *touch = [[touches allObjects] lastObject];
        NSString *menuPath = [NSString stringWithFormat:@"/SPIN/%@/menu", serverName];
		
		if (menuEnabled)
		{
			NSUInteger numTaps = [touch tapCount];
			NSLog(@"numTaps= %d", numTaps);
			if (numTaps>0)
			{
				lo_send(tcpAddr, [menuPath UTF8String], "s", "select");
			}
			else
			{
				CGPoint endTouch = [touch locationInView:self.view];
				
				if (startTouch.x+startTouch.y < endTouch.x+endTouch.y)
					lo_send(tcpAddr, [menuPath UTF8String], "s", "highlightNext");
				else
					lo_send(tcpAddr, [menuPath UTF8String], "s", "highlightPrev");
			}

		}
		
		else
		{
			
			speedLabel.text = @"0";
			NSLog(@"touchedEnded");
			currentSpeed = 0;
			speedScaleValue = 1.0;
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{	
    [self stopSpeedScale];
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet
{
	if (actionSheet != nodesListSheet)
	{
		NSString *string = [NSString stringWithFormat:@"/SPIN/%@/%@-target", serverName, postureName];
		const char *path = [string UTF8String];
		//lo_send(tcpAddr, path, "ss", "setParent", [[NSString stringWithFormat:@"%@-pointer", postureName] UTF8String]);	
		lo_send(tcpAddr, path, "ssi", "setEnabled", [[NSString stringWithFormat:@"%@-target-instructions", postureName] UTF8String], 0);	
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex < 0) return; //[self actionSheetCancel:actionSheet];
	
    calibrating = NO;
    
	if (actionSheet == nodesListSheet)
	{
		[self gotNode:[actionSheet buttonTitleAtIndex:buttonIndex]];
	}
	
	else
	{
		// this is the calibration actionsheet
		
		if (buttonIndex == 0)
		{
			if (motionMode==MOTION_MANAGER)
			{
				[self setMotionZero:self];
				
				NSLog(@"Set zero orientation");
			}
			else if (motionMode==LOCATION_MANAGER)
			{
				calO = yaw+calO;
			
				flatCalibration = YES;
				totalY = 0;
				collectedSamples = 0;
				[self.calibratingSpin startAnimating];
				
				NSLog(@"Recalibrating accelerometer");
			}
			
			//headingLabel.text = [NSString stringWithFormat:@"0"];
			
			[self actionSheetCancel:actionSheet];
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
	if (connected)
	{
		NSString *string = [NSString stringWithFormat:@"/SPIN/%@/%@", serverName, postureName];
		const char *path = [string UTF8String];
		//lo_send(tcpAddr, path, "sfff", "setTranslation", 0.0, 0.0, 1.5);
		lo_send(tcpAddr, path, "ss", "event", "reset");

	}
}
- (IBAction)showFlip
{
	ignoreInfoMessages = YES;
	//[locationManager stopUpdatingHeading];
	
    NSLog(@"showFlip");

    FlipView *f= [[FlipView alloc] initWithNibName:@"FlipView" bundle:[NSBundle mainBundle]];
    f.delegate = self;
    
	//flipView.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:f animated:YES];
    [f release];
}


-(void) FlipViewDidFinish:(FlipView*)controller
{
    NSLog(@"FlipView finished");

    [self connect];
    
    ignoreInfoMessages = NO;
    [self dismissModalViewControllerAnimated:YES];
}

-(void) FlipViewDidCancel:(FlipView*)controller
{
    NSLog(@"FlipView cancelled");
    
    ignoreInfoMessages = NO;
    [self dismissModalViewControllerAnimated:YES];
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


int nodelist_handler(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data)
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
	

	if (argc>2)
	{
		
		NSString *argOne = [NSString stringWithUTF8String:(char*)argv[1]];
		
		
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
			NSLog(@"menu setEnabled %d", self.menuEnabled);
			lo_send(tcpAddr, [[NSString stringWithFormat:@"/SPIN/%@/%@", self.serverName, self.postureName] UTF8String], "sfff", "setVelocity", 0.0, 0.0, 0.0);
			self.currentSpeed = 0;
		}
	}
	
	[pool release];
	return 0;
}


int info_handler(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data)
{
	NTARemoteViewController *self = (NTARemoteViewController*)user_data;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    if ((self.connected == 0) && (!self.ignoreInfoMessages)) {
		
        // args of the INFO message is like this:
        // default 192.168.1.100 54324 54322 224.0.0.1 54323 54321
        // ie,
        // argv[0] = server name
        // argv[1] = server address/ip
        // argv[2] = server UDP listening port
        // argv[3] = server TCP listening port
        // argv[4] = server's transmission address (usually multicast group)
        // argv[5] = server's sending port (UDP)
        // argv[6] = server's sending port (sync/timecode)
        
		const char *tPath = (const char*)argv[0];
		const char *ip = (const char*)argv[1];
		char port[7]; sprintf(port, "%d", (int)lo_hires_val('i', argv[2]));
		char tcpPort[7]; sprintf(tcpPort, "%d", (int)lo_hires_val('i', argv[3]));
		const char *tIp = (const char*)argv[4];
		char tPort[7]; sprintf(tPort, "%d", (int)lo_hires_val('i', argv[5]));
		

		NSLog(@"SPIN INFO: %s %s %s %s %s", tPath, ip, port, tIp, tPort);
		
		udpAddr = lo_address_new(ip, port);
		tcpAddr = lo_address_new(ip, tcpPort);
		NSLog(@"Discovered SPIN server at: %s:%s", ip, port);
		
		
		
		lo_server_thread tServer = lo_server_thread_new_multicast(tIp, tPort, NULL);
		lo_server_thread_add_method(tServer, [[NSString stringWithFormat:@"/SPIN/%s", tPath] UTF8String], NULL, nodelist_handler, self);
		lo_server_thread_add_method(tServer, [[NSString stringWithFormat:@"/SPIN/%s/menu", tPath] UTF8String], NULL, menu_handler, self);
		lo_server_thread_start(tServer);
		NSLog(@"Created OSC receive server for SPIN messages at: %s", lo_server_thread_get_url(tServer));
		
		NSLog(@"Requesting list of UserNodes...");
		lo_send(tcpAddr, [[NSString stringWithFormat:@"/SPIN/%s", tPath] UTF8String], "ss", "getNodeList", "UserNode");
		
		
/*
		NSDictionary *aDict = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSString stringWithUTF8String:ip], @"IP",
							   [NSNumber numberWithInt:port], @"Port", 
							   [NSString stringWithUTF8String:path], @"Path",
								nil];

		
		[self performSelectorOnMainThread:@selector(setupSocketWithArgs:) withObject:aDict waitUntilDone:YES];
		*/
		
		
		//fflush(stdout);		
	}
	
	[pool release];
	
	return 1;
}

- (IBAction)startInfoHandler
{
	//[self performSelector:@selector(notConnected) withObject:nil afterDelay:12];
	
	[self.loadingView setHidden:NO];
	[offlineView setHidden:YES];
	//self.view.userInteractionEnabled = NO;
	infoServer = lo_server_thread_new_multicast("239.0.0.1", "54320", NULL);
	
	if (infoServer != nil)
	{
		lo_server_thread_add_method(infoServer, "/SPIN/__server__", "ssiisii", info_handler, self);
		lo_server_thread_start(infoServer);
	}
	
	NSLog(@"Listening for SPIN messages on: %s", lo_server_thread_get_url(infoServer));
}

- (IBAction)stopInfoHandler
{
    if (infoServer)
    {
        lo_server_thread_free(infoServer); 
        infoServer = 0;
    }
}

- (void)gotNode:(NSString*)pName
{
	//[self.loadingView setHidden:YES];
	//self.view.userInteractionEnabled = YES;
	postureName = pName;
    connected = YES;
}


- (void)sendData
{
	if (!connected) return;

	// note: for motionMode==MOTION_MANAGER, the direction vector is updated
	// upon every new motion message
	if (motionMode==LOCATION_MANAGER)
	{
		/*
		dirX = sin(yaw*PI/180)*cos(pitch*PI/180);
		dirY = cos(yaw*PI/180)*cos(pitch*PI/180);
		dirZ = sin(pitch*PI/180);
		*/
		
		dirY = sin(-pitch/57.2957795 + 1.570796326795) * cos(-yaw/57.2957795);
		dirX = sin(-pitch/57.2957795 + 1.570796326795) * sin(-yaw/57.2957795);
		dirZ = cos(-pitch/57.2957795 + 1.570796326795);
		
	}
	
	if ((udpAddr) && (!calibrating))
	{

		lo_send(udpAddr, [[NSString stringWithFormat:@"/SPIN/%@/%@-pointer", serverName, postureName] UTF8String], "sfff",
				"setOrientation", pitch, 0.0, yaw);
		
		
		if (!menuEnabled)
			lo_send(udpAddr, [[NSString stringWithFormat:@"/SPIN/%@/%@", serverName, postureName] UTF8String], "sfff",
					"setVelocity",
					currentSpeed * speedScaleValue * dirX,
					currentSpeed * speedScaleValue * dirY,
					currentSpeed * speedScaleValue * dirZ
					);
	}
	
	//NSLog(@"in sendData. speed(%.1f) x scale(%.1f) = %.1f, yaw=%.0f pitch=%.0f", currentSpeed, speedScaleValue, currentSpeed * speedScaleValue, yaw, pitch);
	
	speedLabel.text = [NSString stringWithFormat:@"%.1f", currentSpeed * speedScaleValue];
	headingLabel.text = [NSString stringWithFormat:@"%.0f", yaw];
	incLabel.text = [NSString stringWithFormat:@"%.0f", pitch];

	/*
	if (self.ignoreInfoMessages == 0)
		[self performSelector:@selector(sendData) withObject:nil afterDelay:updateRate];
     */
	
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
			
			dirY = sin(-mData.attitude.pitch + 1.570796326795) * cos(-mData.attitude.yaw);
			dirX = sin(-mData.attitude.pitch + 1.570796326795) * sin(-mData.attitude.yaw);
			dirZ = cos(-mData.attitude.pitch + 1.570796326795);
			pitch = mData.attitude.pitch*57.2957795;
			yaw =   mData.attitude.yaw*57.2957795;
			

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
			
		};
		
		[motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:motionHandler];
	}
	else if (!enable && motionManager.deviceMotionActive)
	{
		[motionManager stopDeviceMotionUpdates];
	}
	[[NSUserDefaults standardUserDefaults] setBool:enable forKey:@"motionEnabled"];
	
	//NSLog(@"motionManager enabled? %d", [motionManager isDeviceMotionActive]);
	
	return [motionManager isDeviceMotionActive];
}

- (void) setMotionZero:(id)sender
{
	[zeroAttitude release];
	zeroAttitude = [motionManager.deviceMotion.attitude copy];
	//[[NSUserDefaults standardUserDefaults] setObject:zeroAttitude forKey:@"zeroAttitude"];
}

@end
