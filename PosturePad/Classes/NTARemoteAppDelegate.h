//
//  NTARemoteAppDelegate.h
//  NTARemote
//
//  Created by Sam on 07.07.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NTARemoteViewController;

@interface NTARemoteAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    NTARemoteViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet NTARemoteViewController *viewController;

@end

