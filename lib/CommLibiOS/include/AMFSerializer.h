//
//  AMFSerializer.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 29.06.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BinaryStream.h"


@interface AMFSerializer : NSObject 
+(BinaryStream *)serializeToBytes:(id)obj;
+(BinaryStream *)serializeToBytes:(id)obj type:(int)serializationType;
+(id)deserializeFromBytes:(BinaryStream *)bytes;
+(id)deserializeFromBytes:(BinaryStream *)bytes adapt:(BOOL)doNotAdapt;
+(id)deserializeFromBytes:(BinaryStream *)bytes adapt:(BOOL)doNotAdapt type:(int)serializationType;
+(BOOL)serializeToFile:(id)obj fileName:(NSString *)fileName;
+(id)deserializeFromFile:(NSString *)fileName;
@end
