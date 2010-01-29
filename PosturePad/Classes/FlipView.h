//
//  FlipView.h
//  NTARemote
//
//  Created by Sam on 15.07.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FlipView : UIViewController {
	UITextField *addressField, *portField, *clientField, *speedField;
	UISwitch *screenModeSwitch;
	UIButton *saveButton;
}

@property (nonatomic, retain) IBOutlet UITextField *addressField;
@property (nonatomic, retain) IBOutlet UITextField *portField;
@property (nonatomic, retain) IBOutlet UITextField *clientField;
@property (nonatomic, retain) IBOutlet UITextField *speedField;
@property (nonatomic, retain) IBOutlet UISwitch *screenModeSwitch;
@property (nonatomic, retain) IBOutlet UIButton *saveButton;

- (IBAction)dismissView;

@end
