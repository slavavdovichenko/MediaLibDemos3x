//
//  Types.h
//  RTMPStream
//
//  Created by Vyacheslav Vdovichenko on 7/15/11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/*******************************************************************************************************
 * Types singleton accessor: this is how you should ALWAYS get a reference to the Types class instance *
 *******************************************************************************************************/
#define __types [Types sharedInstance]

@interface Types : NSObject {
	NSMutableDictionary	*abstractMappings;
	NSMutableDictionary	*clientMappings;
	NSMutableDictionary	*serverMappings;
}
@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSString *swiftClassPrefix;

// Singleton accessor:  this is how you should ALWAYS get a reference to the class instance.  Never init your own. 
+(Types *)sharedInstance;
// managed objects support
-(BOOL)isManagedObjectSupport;
-(id)managedInstance:(Class)type;
// type mapping
-(void)addAbstractClassMapping:(Class)abstractType mapped:(Class)mappedType;
-(Class)getAbstractClassMapping:(Class)type;
-(void)addClientClassMapping:(NSString *)clientClass mapped:(Class)mappedServerType;
-(Class)getServerTypeForClientClass:(NSString *)clientClass;
-(NSString *)getClientClassForServerType:(NSString *)serverClassName;
-(NSString *)objectMappedClassName:(id)obj;
-(NSString *)typeMappedClassName:(Class)type;
// type reflection
+(NSString *)objectClassName:(id)obj;
+(NSString *)typeClassName:(Class)type;
+(NSString *)insideTypeClassName:(Class)type;
-(id)classInstance:(Class)type;
-(Class)classByName:(NSString *)className;
+(id)classInstanceByClassName:(NSString *)className;
+(BOOL)isAssignableFrom:(Class)type toObject:(id)obj;
+(NSArray *)propertyKeys:(id)obj;
+(NSArray *)propertyAttributes:(id)obj;
+(NSDictionary *)propertyKeysWithAttributes:(id)obj;
+(NSDictionary *)propertyDictionary:(id)obj;
//-(void)makeSwiftClassPrefix:(NSString *)prefix item:(NSString *)item;
// target/plist options
+(NSString *)targetName;
+(NSDictionary *)getInfoPlist;
+(id)getInfoPlist:(NSString *)key;
// try/catch functionality for swift by wrapping around Objective-C
+(void)tryblock:(void(^)())tryblock catchblock:(void(^)(id exception))catchblock finally:(void(^)())finally;
+(void)tryblock:(void(^)())tryblock catchblock:(void(^)(id exception))catchblock;
+(void)throwObjectAsException:(id)obj;
@end

@interface NSDictionary (Class)
-(id)objectForClassKey:(Class)classKey;
-(id)objectForObjectKey:(id)objectKey;
@end

@interface NSMutableDictionary (Class)
-(void)setObject:(id)anObject forClassKey:(Class)classKey;
-(void)setObject:(id)anObject forObjectKey:(id)objectKey;
@end

@interface NSObject (AMF)
-(id)onAMFSerialize;
-(id)onAMFDeserialize;
@end

@interface NSString (Chars)
-(NSString *)firstCharToUpper;
-(NSString *)stringByTrimmingWhitespace;
+(NSString *)randomString:(int)numCharacters;
@end

@interface NSObject (Properties)
-(Class)ofClass;
-(BOOL)isPropertyResolved:(NSString *)name;
-(BOOL)getPropertyIfResolved:(NSString *)name value:(id *)value;
-(BOOL)resolveProperty:(NSString *)name;
-(BOOL)resolveProperty:(NSString *)name value:(id)value;
-(BOOL)resolveProperties:(NSDictionary *)properties;
@end

