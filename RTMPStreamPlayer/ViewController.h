//
//  ViewController.h
//  RTMPStreamPlayer
//
//  Created by Vyacheslav Vdovichenko on 7/11/12.
//  Copyright (c) 2014 The Midnight Coders, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITextFieldDelegate> {

	IBOutlet UITextField	*hostTextField;
	IBOutlet UITextField	*streamTextField;
    IBOutlet UIImageView    *previewView;
    IBOutlet UIBarButtonItem *btnConnect;
    IBOutlet UIBarButtonItem *btnPlay;
    IBOutlet UILabel         *memoryLabel;
}

-(IBAction)connectControl:(id)sender;
-(IBAction)playControl:(id)sender;

@end
