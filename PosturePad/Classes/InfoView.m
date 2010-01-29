//
//  InfoView.m
//  PosturePad
//
//  Created by Sam on 18.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "InfoView.h"


@implementation InfoView

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
	
	scrollView.contentSize = CGSizeMake(320,520);
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


- (IBAction)done {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)moreInfo {
	UIAlertView *alertView = [[UIAlertView alloc] 
							  initWithTitle:@"More Information" 
							  message:@"Are you sure you want to quit PosturePad and visit the Posture website?"
							  delegate:self 
							  cancelButtonTitle:@"Cancel" 
							  otherButtonTitles:@"Yes", nil];
	
	[alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if(buttonIndex == 1)
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://courchel.net/posture/"]];

}


@end
