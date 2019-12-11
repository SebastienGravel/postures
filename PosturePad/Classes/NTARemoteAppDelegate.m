//
//  NTARemoteAppDelegate.m
//  NTARemote
//
//  Created by Sam on 07.07.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "NTARemoteAppDelegate.h"
#import "NTARemoteViewController.h"

@implementation NTARemoteAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
	
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
    // Override point for customization after app launch    
    //[window addSubview:viewController.view];
    [self.window setRootViewController:viewController];
    [window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[viewController disconnect];
}

- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
