//
//  MPMediaData.h
//  MediaLibiOS
//
//  Created by Vyacheslav Vdovichenko on 10/3/13.
//  Copyright (c) 2013 The Midnight Coders, Inc. All rights reserved.
//

#define IS_MEDIA_ENCODER 1

#define TIMESTAMP_BY_HOST_TIMER 0
#define USE_AUDIO_TIMESTAMP 1

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

#define isEchoCancellation [MPMediaData getEchoCancellationOn]
#define echoCancellationOn [MPMediaData setEchoCancellationOn:YES]
#define echoCancellationOff [MPMediaData setEchoCancellationOn:NO]

#define MP_RTMP_CLIENT_IS_CONNECTED @"RTMP.Client.isConnected"
#define MP_RTMP_CLIENT_STREAM_IS_CREATED @"RTMP.Client.Stream.isCreated"
#define MP_RTMP_CLIENT_STREAM_IS_PLAYING @"RTMP.Client.Stream.Playing"
#define MP_RTMP_CLIENT_STREAM_IS_PAUSED @"RTMP.Client.Stream.isPaused"
#define MP_RTMP_CLIENT_STREAM_IS_STOPPED @"RTMP.Client.Stream.isStopped"

#define MP_STREAM_IS_BUSY @"streamIsBusy"
#define MP_RESOURCE_TEMPORARILY_UNAVAILABLE @"Resource temporarily unavailable" 

#define MP_NETSTREAM_PUBLISH_START @"NetStream.Publish.Start"
#define MP_NETSTREAM_PLAY_START @"NetStream.Play.Start"
#define MP_NETSTREAM_PLAY_STREAM_NOT_FOUND @"NetStream.Play.StreamNotFound"

#define MP_STREAM_SHOULD_VALID_CONNECT @"You should use a valid 'connect', 'attach' or 'stream' method for making the new stream"
#define MP_STREAM_SHOULD_DISCONNECT @"You should use 'disconnect' method before making the new stream"
#define MP_STREAM_SHOULD_STOP @"You should use 'stop' method before making the new stream"

typedef enum {
    MP_VIDEO_CODEC_NONE,
    MP_VIDEO_CODEC_FLV1,
    MP_VIDEO_CODEC_H264,
} MPVideoCodec;

typedef enum {
    MP_AUDIO_CODEC_NONE,
    MP_AUDIO_CODEC_NELLYMOSER,
    MP_AUDIO_CODEC_AAC,
    MP_AUDIO_CODEC_SPEEX,
} MPAudioCodec;

typedef enum {
    SYSTEM_CHANNEL_ID = 3,
    COMMAND_CHANNEL_ID = 4,
    VIDEO_CHANNEL_ID = 8,
    AUDIO_CHANNEL_ID = 9,
} MPMediaChannelID;

typedef enum {
    CONN_DISCONNECTED,
    CONN_CONNECTED,
    STREAM_CREATED,
    STREAM_PLAYING,
    STREAM_PAUSED,
} MPMediaStreamState;

typedef enum {
    RESOLUTION_CUSTOM = -1, // set by user
    RESOLUTION_LOW,         // 144x192px (landscape) & 192x144px (portrait)
    RESOLUTION_CIF,         // 288x352px (landscape) & 352x288px (portrait)
    RESOLUTION_MEDIUM,      // 360x480px (landscape) & 480x368px (portrait)
    RESOLUTION_VGA,         // 480x640px (landscape) & 640x480px (portrait)
    RESOLUTION_HIGH,        // 720x1280px (landscape) & 1280x720px (portrait)
} MPVideoResolution;

typedef enum {
	PUBLISH_RECORD,
	PUBLISH_APPEND,
	PUBLISH_LIVE,
} MPMediaPublishType;

typedef enum {
	MP_AUDIO_PCM_U8,
	MP_AUDIO_PCM_S16,
	MP_AUDIO_PCM_S32,
	MP_AUDIO_PCM_FLT,
	MP_AUDIO_PCM_DBL,
} MPAudioPCMType;

@interface MPMediaData : NSObject
@property uint8_t *data;
@property size_t size;
@property size_t width;
@property size_t height;
@property size_t bytesPerRow;
#if IS_MEDIA_ENCODER
@property int64_t timestamp;
#else
@property uint timestamp;
#endif
@property uint type;
@property CMTime pts;
@property CMTime duration;
@property (retain) id content;

#if IS_MEDIA_ENCODER
-(id)initWithData:(uint8_t *)data size:(size_t)size timestamp:(int64_t)timestamp;
#else
-(id)initWithData:(uint8_t *)data size:(size_t)size timestamp:(uint)timestamp;
#endif

+(void)setEchoCancellationOn:(BOOL)isOn;
+(BOOL)getEchoCancellationOn;
+(BOOL)setAudioStreamBasicDescription:(AudioStreamBasicDescription *)streamDescription pcmType:(MPAudioPCMType)pcmType;
+(void)setAVAudioSessionCategoryPlayAndRecord:(AVAudioSessionCategoryOptions)options;
+(void)routeAudioToSpeaker;
+(uint64_t)hostTimeMs:(uint64_t)nanosec;
+(uint64_t)hostTimeMs;
@end

@protocol MPIMediaStream <NSObject>
-(NSString *)getMediaStreamUrl;
-(void)sendMediaFrame:(MPMediaData *)data;
-(int)writeStream:(uint8_t *)data  lenght:(uint)lenght;
@end

@protocol MPIMediaStreamEvent <NSObject>
-(void)stateChanged:(id)sender state:(MPMediaStreamState)state description:(NSString *)description;
-(void)connectFailed:(id)sender code:(int)code description:(NSString *)description;
@optional
-(void)metadataReceived:(id)sender event:(NSString *)event metadata:(NSDictionary *)metadata;
-(void)pixelBufferShouldBePublished:(CVPixelBufferRef)pixelBuffer timestamp:(int)timestamp;
@end

@protocol MPIMediaEncoder <NSObject>
-(int)setupStream:(id)stream  video:(MPVideoCodec)videoCodecID audio:(MPAudioCodec)audioCodecID orientation:(AVCaptureVideoOrientation)orientation resolution:(MPVideoResolution)resolution videoBitrate:(uint)videoBitrate;
-(void)cleanupStream;
-(void)setVideoCustom:(uint)fps width:(uint)width height:(uint)height;
-(void)setAudioBitrate:(uint)bitRate;
-(int)addVideoFrame:(uint8_t *)data dataSize:(size_t)size pts:(CMTime)pts duration:(CMTime)duration;
#if USE_AUDIO_TIMESTAMP
-(int)addAudioSamples:(uint8_t *)data dataSize:(size_t)size timestampMs:(int64_t)timestampMs hostTimeMs:(int64_t)hostTimeMs;
#else
-(int)addAudioSamples:(uint8_t *)data dataSize:(size_t)size pts:(CMTime)pts;
#endif
-(int)getPendingVideoFrames;
-(double)getCurrentFPS;
@end
