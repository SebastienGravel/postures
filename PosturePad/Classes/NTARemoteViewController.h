//
//  NTARemoteViewController.h
//  NTARemote
//
//  Created by Sam on 07.07.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
//#import <CoreAudio/CoreAudioTypes.h>
#import "FlipView.h"
#import "InfoView.h"


typedef enum { DISABLED, LOCATION_MANAGER, MOTION_MANAGER } MotionMode;

@interface NTARemoteViewController : UIViewController
    <UIAccelerometerDelegate, CLLocationManagerDelegate,
    UIActionSheetDelegate, UIAlertViewDelegate,
    FlipViewDelegate>
{
	
	UIView *loadingView;
	IBOutlet UIImageView *offlineView;
	UILabel *incLabel, *headingLabel, *speedLabel, *loadingLabel;
	NSUInteger collectedSamples;
	UIActivityIndicatorView *calibratingSpin;
	UIButton *calibrateButton;
    //UIButton *flipButton;
	NSString *postureName;
    NSString *serverName;
    NSString *userID;
	float totalY, calY, calO;
	
	float minAccel, maxAccel;
	BOOL userHolding;
	UIActionSheet *calibrateActionSheet;
	
	BOOL connected, ignoreInfoMessages, calibrating;
	double pitch, yaw;
	double dirX, dirY, dirZ;
    float currentTouchY;
	float currentSpeed;
	BOOL flatCalibration, northCalibration;
	
	float updateRate;
	
    NSTimer *sendDataTimer;
    
	NSTimer *speedScaleTimer;
	float speedScaleValue;
	
	BOOL menuEnabled;
	
	
    
	CGPoint startTouch;
	
	MotionMode motionMode;
	
	CMMotionManager *motionManager;
	CMAttitude *zeroAttitude;
    
    // audio level:
    AVAudioRecorder *audioMonitor;
	NSTimer *audioLevelTimer;
	double lowpassResults;
    float lowpassAlpha;
    IBOutlet UIImageView *VUMeter;
    IBOutlet UIView *VUMeterCover;
    IBOutlet UISlider *VUAlphaSlider;
    IBOutlet UIButton *lowpassSwitchButton;
}

@property (nonatomic, retain) IBOutlet UILabel *incLabel;
@property (nonatomic, retain) IBOutlet UILabel *headingLabel;
@property (nonatomic, retain) IBOutlet UILabel *speedLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *calibratingSpin;
@property (nonatomic, retain) IBOutlet UIButton *calibrateButton;
@property (nonatomic, retain) IBOutlet UIView *loadingView;
@property (nonatomic, retain) IBOutlet UILabel *loadingLabel;
@property (nonatomic, retain) CMMotionManager *motionManager;
@property (nonatomic, retain) NSString *postureName;
@property (nonatomic, retain) NSString *serverName;
@property (readwrite) BOOL connected;
@property (readwrite) BOOL ignoreInfoMessages;
@property (readwrite) float currentSpeed;
@property (readwrite) float minAccel;
@property (readwrite) float maxAccel;
@property (readwrite) double pitch;
@property (readwrite) double yaw;

@property (readwrite) BOOL menuEnabled;
@property (readwrite) MotionMode motionMode;

- (void)checkAccumAccel;
//- (void)setupSocketWithArgs:(NSDictionary*)args;
- (IBAction)startInfoHandler;
- (IBAction)stopInfoHandler;

- (IBAction)promptActions;
- (void) speedScale:(NSTimer *)timer;
- (void) startSpeedScale;
- (void) stopSpeedScale;
- (IBAction)resetPosition;
- (IBAction)showFlip;
- (void)sendData;
- (void)connect;
- (void)disconnect;
- (void)gotNode:(NSString*)pName;

- (void) setMotionRate:(int)hz;
- (BOOL) setMotionEnabled:(BOOL)enable;
- (void) setMotionZero:(id)sender;

- (void)audioLevelCallback:(NSTimer *)timer;
- (IBAction)lowpassSwitch:(id)sender;

@end

