//
//  InfoView.h
//  PosturePad
//
//  Created by Sam on 18.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface InfoView : UIViewController {
	IBOutlet UIBarButtonItem *doneButton;
	IBOutlet UIScrollView *scrollView;
	
}

- (IBAction)done;
- (IBAction)moreInfo;

@end
