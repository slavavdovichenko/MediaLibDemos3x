//
//  Responder.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 26.07.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define UNKNOWN_FAULT [Fault fault:@"Unknown fault"  detail:@"Unknown fault" faultCode:@"-9999"]

@interface Fault : NSObject {
    NSString    *message;
    NSString    *detail;
    NSString    *faultCode;
    id context;
}
@property (nonatomic, readonly) NSString *message;
@property (nonatomic, readonly) NSString *detail;
@property (nonatomic, readonly) NSString *faultCode;
@property (nonatomic, assign) id context;

-(id)initWithMessage:(NSString *)_message;
-(id)initWithMessage:(NSString *)_message detail:(NSString *)_detail;
-(id)initWithMessage:(NSString *)_message faultCode:(NSString *)_faultCode;
-(id)initWithMessage:(NSString *)_message detail:(NSString *)_detail faultCode:(NSString *)_faultCode;
+(id)fault:(NSString *)_message;
+(id)fault:(NSString *)_message detail:(NSString *)_detail;
+(id)fault:(NSString *)_message faultCode:(NSString *)_faultCode;
+(id)fault:(NSString *)_message detail:(NSString *)_detail faultCode:(NSString *)_faultCode;
@end


@interface SubscribeResponse : NSObject {
    id              response;
    NSDictionary    *headers;    
}
@property (nonatomic, readonly) id response;
@property (nonatomic, readonly) NSDictionary *headers;

-(id)initWithResponse:(id)_response;
-(id)initWithResponse:(id)_response heasers:(NSDictionary *)_headers;
+(id)response:(id)_response;
+(id)response:(id)_response heasers:(NSDictionary *)_headers;

@end


@protocol IResponder <NSObject>
-(id)responseHandler:(id)response;
-(void)errorHandler:(Fault *)fault;
@end


@interface ResponseContext : NSObject
@property (nonatomic, assign) id response;
@property (nonatomic, assign) id context;
+(id)response:(id)response context:(id)context;
@end


@interface Responder : NSObject <IResponder> {
    id  _responder;
    SEL _responseHandler;
    SEL _errorHandler;
}

@property (nonatomic, retain) Responder *chained;
@property (nonatomic, retain) id context;

-(id)initWithResponder:(id)responder selResponseHandler:(SEL)selResponseHandler selErrorHandler:(SEL)selErrorHandler;
+(id)responder:(id)responder selResponseHandler:(SEL)selResponseHandler selErrorHandler:(SEL)selErrorHandler;
@end


@interface SubscribeResponder : Responder 
@end

@interface ResponderBlocksContext : NSObject
+(Responder *)responderBlocksContext:(void(^)(id))responseBlock error:(void(^)(Fault *))errorBlock;
@end

