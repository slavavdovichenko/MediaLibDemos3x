//
//  FlashorbBinaryWriter.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 22.03.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BinaryStream.h"


@interface FlashorbBinaryWriter : BinaryWriter
-(BOOL)writeUInteger:(unsigned int)value;
-(BOOL)writeUInt16:(unsigned short)value;
-(BOOL)writeUInt24:(unsigned int)value;
-(BOOL)writeInt:(int)value;
-(BOOL)writeLong:(long)value;
-(BOOL)writeVarInt:(int)value;
-(BOOL)writeString:(NSString *)str;
-(BOOL)writeLongString:(NSString *)str;
-(BOOL)writeStringEx:(NSString *)str;
@end
