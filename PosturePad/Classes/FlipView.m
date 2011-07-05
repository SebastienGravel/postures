//
//  FlipView.m
//  NTARemote
//
//  Created by Sam on 15.07.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FlipView.h"


@implementation FlipView

//@synthesize addressField, portField, saveButton, clientField, speedField, screenModeSwitch;
@synthesize delegate;

NSUserDefaults *defaults;

- (void)viewDidLoad
{
	defaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"Saved defaults: %@", defaults);
    
	autoDiscoverySwitch.on = ![defaults boolForKey:@"disableDiscovery"];
    /*
    if (!autoDiscoverySwitch.on)
    {
        serverNameField.text = [defaults stringForKey:@"serverName"];
        serverAddrField.text = [defaults stringForKey:@"serverAddr"];
        serverUdpField.text =  [defaults stringForKey:@"serverUdp"];
        serverTcpField.text =  [defaults stringForKey:@"serverTcp"];
        userIdField.text =     [defaults stringForKey:@"userID"];
    }
    */
    [calibrationButton setSelected:(![defaults boolForKey:@"disableRecalibration"])];
    
    
    // call didSwitch method so that textfields get initialized:
    [self didSwitch:autoDiscoverySwitch];
}


- (void)viewWillAppear:(BOOL)animated
{
	//[self.speedField becomeFirstResponder];
	[defaults synchronize];
}

- (IBAction) didSwitch:(UISwitch*)sw
{
    for (id button in allTextFields)
    {
        [button setEnabled:(!sw.on)];
    }
    
    if (!sw.on)
    {
        serverNameField.text = [defaults stringForKey:@"serverName"];
        serverAddrField.text = [defaults stringForKey:@"serverAddr"];
        serverUdpField.text =  [defaults stringForKey:@"serverUdp"];
        serverTcpField.text =  [defaults stringForKey:@"serverTcp"];
        userIdField.text =     [defaults stringForKey:@"userID"];
    } else {
        serverNameField.text = @"";
        serverAddrField.text = @"";
        serverUdpField.text =  @"";
        serverTcpField.text =  @"";
        userIdField.text =     @"";
    }
}

- (IBAction) calibrationToggle:(UIButton*)bt
{
    [bt setSelected:(!bt.selected)];
}

- (IBAction) save:(id)sender
{
    if (!autoDiscoverySwitch.on)
    {
        [defaults setObject:serverNameField.text   forKey:@"serverName"];
        [defaults setObject:serverAddrField.text   forKey:@"serverAddr"];
        [defaults setObject:serverUdpField.text    forKey:@"serverUdp"];
        [defaults setObject:serverTcpField.text    forKey:@"serverTcp"];
        [defaults setObject:userIdField.text       forKey:@"userID"];
    }
	[defaults setBool:!autoDiscoverySwitch.on      forKey:@"disableDiscovery"];
	[defaults setBool:!calibrationButton.selected  forKey:@"disableRecalibration"];
	[defaults synchronize];
    
    [self close:sender];
}

- (IBAction) close:(id)sender
{
    if (delegate)
        [self.delegate FlipViewDidFinish:self];
    else
        [self dismissModalViewControllerAnimated:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y -= 70;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.35];
    
    [self.view setFrame:viewFrame];
    
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.35];
    
    [self.view setFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height)];
    
    [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    [super dealloc];
}


@end
