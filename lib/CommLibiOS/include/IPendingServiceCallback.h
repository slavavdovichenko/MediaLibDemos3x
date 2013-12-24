//
//  IPendingServiceCallback.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 08.04.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

//#import <UIKit/UIKit.h>
#import "IServiceCall.h"

@protocol IPendingServiceCallback <NSObject>
-(void)resultReceived:(id <IServiceCall>)call;
-(void)connectFailedEvent:(int)code description:(NSString *)description;
@end
