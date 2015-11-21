//
//  MPMediaDecoder.h
//  MediaLibiOS
//
//  Created by Vyacheslav Vdovichenko on 9/30/13.
//  Copyright 2013 The Midnight Coders, Inc. All rights reserved.
//

#define IS_STREAMIMAGEVIEW_PUBLIC 1
#define IS_AUDIO_ARBITRAGE 1

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
#import "MPMediaData.h"

@protocol IVideoPlayer, IAudioPlayer, MPIMediaStreamEvent;

@interface MPMediaDecoder : NSObject
#if IS_STREAMIMAGEVIEW_PUBLIC
@property (nonatomic, assign) UIImageView *streamImageView;
#endif
@property (nonatomic, assign) id <MPIMediaStreamEvent> delegate;
@property (nonatomic, retain) id <IVideoPlayer> video;
@property (nonatomic, retain) id <IAudioPlayer> audio;
@property (nonatomic, retain) NSArray *parameters;
@property (readonly) MPMediaStreamState state;
@property (readonly) int videoCodecId;
@property (readonly) int audioCodecId;
@property BOOL isRealTime;
@property uint clientBufferMs;
@property CGFloat scale;
@property UIImageOrientation orientation;

-(id)initWithView:(UIImageView *)view;

-(void)setupStream:(id)stream;
-(void)cleanupStream;
-(void)pause;
-(void)resume;
-(int)getPendingFrames;

@end
