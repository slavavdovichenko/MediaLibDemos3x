//
//  MPMediaDecoder.h
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
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>

@protocol IVideoPlayer, IAudioPlayer;

@interface MPMediaDecoder : NSObject
@property (nonatomic, retain) id <IVideoPlayer> video;
@property (nonatomic, retain) id <IAudioPlayer> audio;
@property CGFloat scale;
@property UIImageOrientation orientation;

-(id)initWithView:(UIImageView *)view;

-(void)setupStream:(id)stream;
-(void)cleanupStream;
@end
