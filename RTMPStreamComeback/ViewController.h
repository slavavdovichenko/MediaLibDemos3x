//
//  ViewController.h
//  RTMPStreamComeback
//
//  Created by Vyacheslav Vdovichenko on 11/13/12.
//  Copyright (c) 2014 The Midnight Coders, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController {
    
    IBOutlet UIView          *previewView;
    IBOutlet UIImageView     *streamView;
    IBOutlet UIBarButtonItem *btnConnect;
    IBOutlet UIBarButtonItem *btnToggle;
    IBOutlet UIBarButtonItem *btnPublish;
    IBOutlet UILabel         *memoryLabel;
}

-(IBAction)connectControl:(id)sender;
-(IBAction)publishControl:(id)sender;
-(IBAction)camerasToggle:(id)sender;

@end
