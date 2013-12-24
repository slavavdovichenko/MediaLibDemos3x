//
//  BinaryCodec.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 08.09.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEFAULT_MAX_SIZE 65535

@interface Base64 : NSObject 
+(NSString *)encode:(const uint8_t *)input length:(NSInteger)length;
+(NSString *)encode:(NSData *)rawBytes;
+(NSData *)decode:(const char *)string length:(NSInteger)inputLength;
+(NSData *)decode:(NSString *)string;
//
+(NSArray *)encodeToStringArray:(NSData *)rawBytes limit:(size_t)limit;
+(NSArray *)encodeToStringArray:(NSData *)rawBytes;
+(NSData *)decodeFromStringArray:(NSArray *)stringArray;
@end
