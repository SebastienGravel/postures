//
//  FlipView.h
//  NTARemote
//
//  Created by Sam on 15.07.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FlipViewDelegate;


@interface FlipView : UIViewController
    <UITextFieldDelegate>
{
    id <FlipViewDelegate> delegate;

    
	IBOutlet UITextField *serverNameField;
    IBOutlet UITextField *serverAddrField, *serverTcpField, *serverUdpField;
	IBOutlet UITextField *userIdField;
    IBOutlet UISwitch *autoDiscoverySwitch;
    IBOutlet UIButton *calibrationButton;
    
    IBOutletCollection(UITextField) NSArray *allTextFields;
	//UIButton *saveButton;
}

@property (nonatomic, assign) id <FlipViewDelegate> delegate;

- (IBAction) didSwitch:(UISwitch*)sw;
- (IBAction) calibrationToggle:(UIButton*)bt;
- (IBAction) save:(id)sender;
- (IBAction) close:(id)sender;

@end

@protocol FlipViewDelegate
- (void)FlipViewDidFinish:(FlipView *)controller;
@end
