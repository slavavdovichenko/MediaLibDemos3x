//
//  FlashorbBinaryReader.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 14.03.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BinaryStream.h"

@interface FlashorbBinaryReader : BinaryReader
-(int)readVarInteger;
-(unsigned int)readUnsignedShort;
-(unsigned int)readUInt24;
-(unsigned int)readUInteger;
-(int)readInteger;
-(unsigned long)readULong;
-(double)readDouble;
// !!! Need to be free after using !!!
-(char *)readUTF;
// !!! Need to be free after using !!!
-(char *)readUTF:(int)len;
-(NSString *)readString;
@end
