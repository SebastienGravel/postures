//
//  FlipView.m
//  NTARemote
//
//  Created by Sam on 15.07.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FlipView.h"


@implementation FlipView

@synthesize addressField, portField, saveButton, clientField, speedField, screenModeSwitch;


NSUserDefaults *defaults;

- (void)viewDidLoad {
	defaults = [NSUserDefaults standardUserDefaults];
	self.speedField.text = [defaults stringForKey:@"Speed"];
	self.screenModeSwitch.on = [defaults boolForKey:@"ScreenMode"];
}


- (void)viewWillAppear:(BOOL)animated {
	[self.speedField becomeFirstResponder];
	[defaults synchronize];

}


- (IBAction)dismissView {
	[defaults setFloat:[self.speedField.text floatValue] forKey:@"Speed"];
	[defaults setBool:self.screenModeSwitch.on forKey:@"ScreenMode"];
	[defaults synchronize];
	
	[self dismissModalViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)dealloc {
    [super dealloc];
}


@end
