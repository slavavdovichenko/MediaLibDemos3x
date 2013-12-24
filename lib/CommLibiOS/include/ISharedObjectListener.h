//
//  ISharedObjectListener.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 19.04.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

//#import <UIKit/UIKit.h>

@protocol IClientSharedObject; 

@protocol ISharedObjectListener <NSObject>

/**
 * Called when a client connects to a shared object.
 * 
 * @param so
 *            the shared object
 */
-(void)onSharedObjectConnect:(id <IClientSharedObject>)so;

/**
 * Called when a client disconnects from a shared object.
 * 
 * @param so
 *            the shared object
 */
-(void)onSharedObjectDisconnect:(id <IClientSharedObject>)so;

/**
 * Called when a shared object attribute is updated.
 * 
 * @param so
 *            the shared object
 * @param key
 *            the name of the attribute
 * @param value
 *            the value of the attribute
 */
-(void)onSharedObjectUpdate:(id <IClientSharedObject>)so withKey:(id)key andValue:(id)value;

/**
 * Called when multiple attributes of a shared object are updated.
 * 
 * @param so
 *            the shared object
 * @param values
 *            the new attributes of the shared object
 */
//-(void)onSharedObjectUpdate:(id <IClientSharedObject>)so withValues:(id <IAttributeStore>)values;

/**
 * Called when multiple attributes of a shared object are updated.
 * 
 * @param so
 *            the shared object
 * @param values
 *            the new attributes of the shared object
 */
-(void)onSharedObjectUpdate:(id <IClientSharedObject>)so withDictionary:(NSDictionary *)values;

/**
 * Called when an attribute is deleted from the shared object.
 * 
 * @param so
 *            the shared object
 * @param key
 *            the name of the attribute to delete
 */
-(void)onSharedObjectDelete:(id <IClientSharedObject>)so withKey:(NSString *)key;

/**
 * Called when all attributes of a shared object are removed.
 * 
 * @param so
 *            the shared object
 */
-(void)onSharedObjectClear:(id <IClientSharedObject>)so;

/**
 * Called when a shared object method call is sent.
 * 
 * @param so
 *            the shared object
 * @param method
 *            the method name to call
 * @param params
 *            the arguments
 */
-(void)onSharedObjectSend:(id <IClientSharedObject>)so withMethod:(NSString *)method andParams:(NSArray *)parms;


@end
