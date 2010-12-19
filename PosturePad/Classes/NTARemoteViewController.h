//
//  NTARemoteViewController.h
//  NTARemote
//
//  Created by Sam on 07.07.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "FlipView.h"
#import "InfoView.h"


@interface NTARemoteViewController : UIViewController <UIAccelerometerDelegate, CLLocationManagerDelegate, UIActionSheetDelegate> {
	FlipView *flipView;
	InfoView *instructionsView;
	
	UIView *loadingView;
	IBOutlet UIImageView *offlineView;
	UILabel *incLabel, *headingLabel, *speedLabel, *loadingLabel;
	NSUInteger collectedSamples;
	UIActivityIndicatorView *calibratingSpin;
	UIButton *calibrateButton, *flipButton;
	NSString *postureName;
	float totalY, calY, calO;
	
	int currentHeading, currentInclination, connected, dontConnect;
	float currentSpeed, currentFakeOrientation, pSpeedX, pSpeedY, pSpeedZ;
	BOOL screenMode, flatCalibration, northCalibration;
	
	NSTimer *speedScaleTimer;
	float speedScaleValue;
	
	BOOL menuEnabled;
	
	CGPoint startTouch;
	
	CMMotionManager *motionManager;
	CMAttitude *zeroAttitude;
}

@property (nonatomic, retain) IBOutlet UILabel *incLabel;
@property (nonatomic, retain) IBOutlet UILabel *headingLabel;
@property (nonatomic, retain) IBOutlet UILabel *speedLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *calibratingSpin;
@property (nonatomic, retain) IBOutlet UIButton *calibrateButton;
@property (nonatomic, retain) IBOutlet UIButton *flipButton;
@property (nonatomic, retain) IBOutlet UIView *loadingView;
@property (nonatomic, retain) IBOutlet UILabel *loadingLabel;
@property (nonatomic, retain) CMMotionManager *motionManager;
@property (nonatomic, retain) NSString *postureName;
@property (readwrite) int connected;
@property (readwrite) int dontConnect;
@property (readwrite) float currentSpeed;
@property (readwrite) BOOL menuEnabled;

- (void)setupSocketWithArgs:(NSDictionary*)args;
- (IBAction)getSockets;
- (IBAction)promptActions;
- (void) speedScale:(NSTimer *)timer;
- (IBAction)resetPosition;
- (IBAction)showFlip;
- (IBAction)showInstructions;
- (void)sendData;
- (void)disconnect;
- (void)gotNode:(NSString*)pName;

- (void) setMotionRate:(int)hz;
- (BOOL) setMotionEnabled:(BOOL)enable;
- (void) setMotionZero:(id)sender;

@end

