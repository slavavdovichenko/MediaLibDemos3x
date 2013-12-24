//
//  IClientSharedObjectDelegate.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 12.05.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ISharedObjectMessage;

@protocol IClientSharedObjectDelegate <NSObject>
-(void)makeUpdateMessage:(id <ISharedObjectMessage>)message;
@end
