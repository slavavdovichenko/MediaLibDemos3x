//
//  MemoryTicker.h
//  CommLibiOS
//
//  Created by Vyacheslav Vdovichenko on 4/3/12.
//  Copyright (c) 2012 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MemoryTicker : NSObject {
    
    id      responder;
    SEL     selGetMemory;
    BOOL    inBytes;
    BOOL    asNumber;
    float   tick;
}
@property BOOL inBytes;
@property BOOL asNumber;

-(id)initWithResponder:(id)_responder andMethod:(SEL)method;

-(void)applicationUsedMemoryReport;

+(double)getAvailableMemoryInBytes;
+(double)getAvailableMemoryInKiloBytes;
+(NSString *)showAvailableMemoryInBytes;
+(NSString *)showAvailableMemoryInKiloBytes;
-(double)getAvailableMemory;
-(NSString *)showAvailableMemory;
-(void)tickerStart:(float)aTick;
-(void)tickerStart;
-(void)tickerStop;
@end
