//
//  NTARemoteViewController.h
//  NTARemote
//
//  Created by Sam on 07.07.09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
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
}

@property (nonatomic, retain) IBOutlet UILabel *incLabel;
@property (nonatomic, retain) IBOutlet UILabel *headingLabel;
@property (nonatomic, retain) IBOutlet UILabel *speedLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *calibratingSpin;
@property (nonatomic, retain) IBOutlet UIButton *calibrateButton;
@property (nonatomic, retain) IBOutlet UIButton *flipButton;
@property (nonatomic, retain) IBOutlet UIView *loadingView;
@property (nonatomic, retain) IBOutlet UILabel *loadingLabel;
@property (readwrite) int connected;
@property (readwrite) int dontConnect;

- (void)setupSocketWithArgs:(NSDictionary*)args;
- (IBAction)getSockets;
- (IBAction)promptActions;
- (IBAction)showFlip;
- (IBAction)showInstructions;
- (void)sendData;
- (void)disconnect;
- (void)gotNode:(NSString*)pName;


@end

