//
//  ViewController.h
//  RTMPStreamPublisher
//
//  Created by Vyacheslav Vdovichenko on 7/10/12.
//  Copyright (c) 2012 The Midnight Coders, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITextFieldDelegate> {
    
	IBOutlet UITextField	*hostTextField;
	IBOutlet UITextField	*streamTextField;
    IBOutlet UIView         *previewView;
    IBOutlet UIBarButtonItem *btnConnect;
    IBOutlet UIBarButtonItem *btnToggle;
    IBOutlet UIBarButtonItem *btnPublish;
    IBOutlet UILabel        *memoryLabel;
    
}

-(IBAction)connectControl:(id)sender;
-(IBAction)publishControl:(id)sender;
-(IBAction)camerasToggle:(id)sender;

@end
