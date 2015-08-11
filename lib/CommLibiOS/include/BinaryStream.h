//
//  BinaryStream.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 14.03.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef union {
	char _buf[8];
    long _long;
    double _double;
} u_double_t;

@interface BinaryStream : NSObject {
	char			*buffer;
	size_t			size;
	unsigned int	position;
    int             error;
}
@property (readonly) char *buffer;
@property (readonly) size_t size;
@property (readonly) unsigned int position;
@property (readonly) int error;

-(id)initWithStream:(char *)stream andSize:(size_t)length;
-(id)initWithAllocation:(size_t)length;
+(id)streamWithStream:(char *)stream andSize:(size_t)length;
+(id)streamWithAllocation:(size_t)length;
-(void)print;
-(void)print:(BOOL)visable;
-(void)print:(BOOL)visable start:(int)start finish:(int)finish;
+(void)invertOrder:(char *)stream ofSize:(size_t)length;
-(BOOL)extend:(size_t)length;
-(BOOL)extendTo:(size_t)length;
-(int)remaining;
-(BOOL)seek:(unsigned int)pos;
-(BOOL)begin;
-(BOOL)end;
-(BOOL)next;
-(BOOL)previous;
-(BOOL)put:(char)value;
-(char)get;
-(int)shift;
-(int)trunc;
-(int)move:(int)shift;
-(BOOL)append:(char *)buf length:(size_t)length;
-(void)empty;
-(void)clear;
@end


@interface BinaryWriter : BinaryStream
-(BOOL)extendForWrite:(size_t)length;
-(BOOL)write:(char *)buf length:(size_t)length;
-(BOOL)writeByte:(int)value;
-(BOOL)writeInt16:(short)value;
-(BOOL)writeInt32:(int)value;
-(BOOL)writeInt64:(long)value;
-(BOOL)writeDouble:(double)value;
-(BOOL)writeBoolean:(BOOL)value;
-(BOOL)writeChar:(char)value;
-(BOOL)writeChars:(char *)str;
@end


@interface BinaryReader : BinaryStream
-(int)read:(char *)buf length:(size_t)length;
-(int)readByte;
-(int)readInt16;
-(uint)readUInt24BE;
-(int)readInt32;
-(uint)readUInt32BE;
-(long)readInt64;
-(uint)readExtendedMediumUIntBE;
-(double)readDouble;
-(BOOL)readBoolean;
-(char)readChar;
// !!! Need to be free after using !!!
-(char *)readChars:(int)count;
@end
