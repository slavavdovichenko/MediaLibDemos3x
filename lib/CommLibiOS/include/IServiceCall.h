//
//  IServiceCall.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 07.04.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

//#import <UIKit/UIKit.h>


@protocol IServiceCall <NSObject>
-(BOOL)isSuccess;
-(NSString *)getServiceMethodName;
-(NSString *)getServiceName;
-(NSArray *)getArguments;
-(uint)getStatus;
-(NSException *)getException;
-(void)setInvokeId:(int)_invokeId;
-(int)getInvokeId;
@optional
-(void)setStatus:(uint)status;
-(void)setException:(NSException *)exception;
@end
