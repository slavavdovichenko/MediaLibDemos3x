//
//  StreamReader.h
//  MediaLibiOS
//
//  Created by Vyacheslav Vdovichenko on 9/30/13.
//  Copyright 2013 The Midnight Coders, Inc. All rights reserved.
//

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#define UIImage NSImage
#endif

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface StreamReader : NSThread
-(void)setStreamImageView:(UIImageView *)streamImageView;
-(void)setupStream:(id)stream;
-(void)cleanupStream;
@end
