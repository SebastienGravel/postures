//
//  main.m
//  NTARemote
//
//  Created by Sam on 07.07.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTARemoteAppDelegate.h"


int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([NTARemoteAppDelegate class]));
    [pool release];
    return retVal;
}
