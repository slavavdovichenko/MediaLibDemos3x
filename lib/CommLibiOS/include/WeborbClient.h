//
//  WeborbClient.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 27.06.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ISubscribedHandler <NSObject>
-(void)subscribed:(id)info;
@end

@class Engine, RTMPClient, IdInfo, SubscribedHandler, Subscription, V3Message;
@protocol IResponder;

@interface WeborbClient : NSObject <ISubscribedHandler> {
    
    SubscribedHandler   *subscribedHandler;
    Engine              *engine;
    IdInfo              *idInfo;
    NSMutableDictionary *subscribers;
}
@property (nonatomic, retain) SubscribedHandler *subscribedHandler;
@property (nonatomic, assign, readonly, getter = getRTMP) RTMPClient *RTMP;
@property (nonatomic, assign, getter = getRequestHeaders, setter = setRequestHeaders:) NSMutableDictionary *requestHeaders;
@property (nonatomic, assign, getter = getHttpHeaders, setter = setHttpHeaders:) NSMutableDictionary *httpHeaders;

-(id)initWithUrl:(NSString *)gatewayURL;
-(id)initWithUrl:(NSString *)gatewayURL destination:(NSString *)destination;
-(void)setClientClass:(Class)type forServerType:(NSString *)serverTypeName;
// sync invokes
-(id)invoke:(NSString *)methodName args:(NSArray *)args;
-(id)invoke:(NSString *)className method:(NSString *)methodName args:(NSArray *)args;
// async invokes
-(void)invoke:(NSString *)methodName args:(NSArray *)args responder:(id <IResponder>)responder;
-(void)invoke:(NSString *)className method:(NSString *)methodName args:(NSArray *)args responder:(id <IResponder>)responder;
//
-(void)publish:(id)message;
-(void)publish:(id)message subtopic:(NSString *)subtopic;
-(void)publish:(id)message headers:(NSDictionary *)headers;
-(void)publish:(id)message subtopic:(NSString *)subtopic headers:(NSDictionary *)headers;
-(void)publish:(id)message responder:(id <IResponder>)responder;
-(void)publish:(id)message responder:(id <IResponder>)responder subtopic:(NSString *)subtopic;
-(void)publish:(id)message responder:(id <IResponder>)responder headers:(NSDictionary *)headers;
-(void)publish:(id)message responder:(id <IResponder>)responder subtopic:(NSString *)subtopic headers:(NSDictionary *)headers;
//
-(Subscription *)subscribe:(id <IResponder>)responder;
-(Subscription *)subscribe:(id <IResponder>)responder subtopic:(NSString *)subTopic;
-(Subscription *)subscribe:(id <IResponder>)responder subtopic:(NSString *)subTopic selector:(NSString *)selector;
//
-(void)unsubscribe;
-(void)unsubscribe:(NSString *)subTopic;
-(void)unsubscribe:(NSString *)subTopic selector:(NSString *)selector;
//
-(void)sendMessage:(V3Message *)v3Msg responder:(id <IResponder>)responder;
//
-(void)stop;
@end


@interface IdInfo : NSObject {
    NSString    *clientId;
    NSString    *dsId;
    NSString    *destination;
}
@property (nonatomic, retain) NSString *clientId;
@property (nonatomic, retain) NSString *dsId;
@property (nonatomic, retain) NSString *destination;
@end


@interface SubscribedHandler : NSObject <ISubscribedHandler> {
    id  _responder;
    SEL _subscribedHandler;
}

-(id)initWithResponder:(id)responder selSubscribedHandler:(SEL)selSubscribedHandler;
+(id)responder:(id)responder selSubscribedHandler:(SEL)selSubscribedHandler;
@end
