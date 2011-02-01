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

typedef enum { DISABLED, LOCATION_MANAGER, MOTION_MANAGER } MotionMode;

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
	
	float minAccel, maxAccel;
	BOOL userHolding;
	UIActionSheet *calibrateActionSheet;
	
	int connected, dontConnect;
	double pitch, yaw;
	double dirX, dirY, dirZ;
	float currentSpeed;
	BOOL flatCalibration, northCalibration;
	
	float updateRate;
	
	NSTimer *speedScaleTimer;
	float speedScaleValue;
	
	BOOL menuEnabled;
	
	
	
	CGPoint startTouch;
	
	MotionMode motionMode;
	
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
@property (readwrite) float minAccel;
@property (readwrite) float maxAccel;
@property (readwrite) double pitch;
@property (readwrite) double yaw;

@property (readwrite) BOOL menuEnabled;
@property (readwrite) MotionMode motionMode;

- (void)checkAccumAccel;
//- (void)setupSocketWithArgs:(NSDictionary*)args;
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

