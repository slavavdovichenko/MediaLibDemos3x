//
//  RTMPClient.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 21.03.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IPendingServiceCallback.h"
#import "IClientSharedObject.h"
#import "ISharedObjectListener.h"

#define SOCKET_THREAD_IS_RUNNING @"SocketThreadIsRunning"


@protocol IRTMPClientDelegate <IPendingServiceCallback>
-(void)connectedEvent;
-(void)disconnectedEvent;
@end


@class Packet, MetaData;
@protocol IStreamDispatcher, IPendingServiceCall;

@interface RTMPClient : NSObject <NSStreamDelegate>

@property (nonatomic, assign, getter = getDelegates, setter = addDelegate:) id <IRTMPClientDelegate> delegate;
@property float	timeoutHandshake;

// init
-(id)init:(NSString *)url;
-(id)init:(NSString *)url andParams:(NSArray *)params;

// spawn socket thread
-(void)spawnSocketThread;
-(NSThread *)getSocketThread;

// delegates
-(BOOL)isDelegate:(id)owner;
-(void)removeDelegate:(id)owner;

// connect
-(NSString *)getURL;
-(void)connect;
-(void)connect:(NSString *)url;
-(void)connect:(NSString *)url andParams:(NSArray *)params;
-(BOOL)connected;
-(void)disconnect;
-(void)disconnect:(id)owner;

// invokes
-(int)invoke:(NSString *)method withArgs:(NSArray *)args responder:(id <IPendingServiceCallback>)responder;

// get SO
-(id <IClientSharedObject>)getSharedObject:(NSString *)name persistent:(BOOL)persistent owner:(id <ISharedObjectListener>)owner;

// set client chunk size
-(void)setClientChunkSize:(int)size;

// hidden public - only for internal usage
-(int)nextInvokeId;
-(void)sendMessage:(Packet *)message;
-(int)invoke:(NSString *)method withArgs:(NSArray *)args responder:(id <IPendingServiceCallback>)responder transactionID:(int)tID channelId:(int)cID  streamId:(int)sID;
-(void)flexInvoke:(NSString *)method message:(id)obj responder:(id <IPendingServiceCallback>)responder;
-(void)metadata:(MetaData *)metadata streamId:(int)streamId channelId:(int)channelId timestamp:(int)timestamp;
-(void)clearPendingCalls;
-(NSArray *)rtmpWritingQueue;
-(int)pendingTypedPackets:(int)type streamId:(int)streamId;
// stream
-(BOOL)addStreamPlayer:(id <IStreamDispatcher>)player streamId:(int)streamId;
-(BOOL)removeStreamPlayer:(id <IStreamDispatcher>)player streamId:(int)streamId;
-(int)writeStream:(uint)streamId data:(uint8_t *)data  lenght:(uint)lenght;

@end

// AsynCall Class makes Pending Service Processing

#pragma mark -
#pragma mark AsynCall Class 

@interface AsynCall : NSObject <IPendingServiceCallback> {
    id owner;
    SEL method;
}

-(id)initWithCall:(id)processor method:(SEL)sel;
+(id)call:(id)processor method:(SEL)sel;
@end

