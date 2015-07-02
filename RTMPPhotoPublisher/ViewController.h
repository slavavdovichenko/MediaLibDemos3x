//
//  ViewController.h
//  RTMPPhotoPublisher
//
//  Created by Slava Vdovichenko on 6/29/15.
//  Copyright (c) 2015 The Midnight Coders, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) IBOutlet UIView *previewView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UIButton *btnTakePhoto;
-(IBAction)takePhoto:(id)sender;
@end

