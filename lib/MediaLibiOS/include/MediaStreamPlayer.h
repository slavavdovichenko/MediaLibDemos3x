//
//  MediaStreamPlayer.h
//  MediaLibiOS
//
//  Created by Vyacheslav Vdovichenko on 9/18/11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPMediaData.h"
#import "RTMPClient.h"

@protocol IVideoPlayer;
@class VideoStream, SysTimer, NellyMoserDecoder;

@interface MediaStreamPlayer : NSObject
@property (nonatomic, assign) id <MPIMediaStreamEvent> delegate;
@property (nonatomic, retain) id <IVideoPlayer> player;
@property (nonatomic, retain) NSArray *parameters;
@property (readonly) MPMediaStreamState state;

-(id)init:(NSString *)url;
-(id)initWithClient:(RTMPClient *)client;

-(BOOL)connect:(NSString *)url name:(NSString *)name;
-(BOOL)attach:(RTMPClient *)client name:(NSString *)name;
-(BOOL)stream:(NSString *)name;
-(BOOL)isPlaying;
-(BOOL)start;
-(void)pause;
-(void)resume;
-(BOOL)stop;
-(void)disconnect;
@end
