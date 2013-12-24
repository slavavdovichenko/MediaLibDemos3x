//
//  VideoPlayer.h
//  MediaLibiOS
//
//  Created by Vyacheslav Vdovichenko on 4/28/12.
//  Copyright (c) 2012 The Midnight Coders, Inc. All rights reserved.
//

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#define UIImage NSImage
#endif
#import "MPMediaData.h"


@protocol IVideoPlayer <NSObject>
-(void)playVideoFrame:(MPMediaData *)data;
@optional
-(void)playImageBuffer:(CVPixelBufferRef)frameBuffer;
@end


@interface FramesPlayer : NSObject <IVideoPlayer>
@property CGFloat scale;
@property UIImageOrientation orientation;

-(id)initWithView:(UIImageView *)view;
@end;