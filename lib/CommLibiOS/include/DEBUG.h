//
//  DEBUG.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 18.05.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DebLog : NSObject 
+(void)setIsActive:(BOOL)isActive;
+(BOOL)getIsActive;
+(void)log:(NSString *)format,...;
+(void)log:(BOOL)show text:(NSString *)format,...;
+(void)logY:(NSString *)format,...;
+(void)logN:(NSString *)format,...;
@end
