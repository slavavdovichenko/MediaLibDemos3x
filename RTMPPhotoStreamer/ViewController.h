//
//  ViewController.h
//  RTMPPhotoStreamer
//
//  Created by Slava Vdovichenko on 6/26/15.
//  Copyright (c) 2015 The Midnight Coders, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController {
    
    IBOutlet UITextField    *textField;
    IBOutlet UILabel        *labelLive;
    IBOutlet UISwitch       *switchLive;
    IBOutlet UIView         *previewView;
    IBOutlet UIButton       *btnPublish;
    IBOutlet UIButton       *btnStop;
    IBOutlet UIButton       *btnToggle;
    IBOutlet UIButton       *btnPhoto;
    IBOutlet UIActivityIndicatorView *netActivity;
}

-(IBAction)publish:(id)sender;
-(IBAction)stop:(id)sender;
-(IBAction)toggle:(id)sender;
-(IBAction)photo:(id)sender;

@end

