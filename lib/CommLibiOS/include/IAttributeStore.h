//
//  IAttributeStore.h
//  RTMPStream
//
//  Created by Вячеслав Вдовиченко on 19.04.11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

//#import <UIKit/UIKit.h>


@protocol IAttributeStore <NSObject>
/**
 * Get the attribute names
 * @return set containing all attribute names
 */
-(NSArray *)getAttributeNames;

/**
 * Get the attributes. The resulting map will be read-only.
 * 
 * @return map containing all attributes
 */
-(NSDictionary *)getAttributes;

/**
 * Set an attribute on this object
 * @param name  the name of the attribute to change
 * @param value the new value of the attribute
 * @return true if the attribute value changed otherwise false
 */
-(BOOL)setAttribute:(NSString *)name object:(id)value;

/**
 * Set multiple attributes on this object
 * @param values the attributes to set
 */
-(void)setAttributes:(NSDictionary *)values;

/**
 * Set multiple attributes on this object
 * @param values the attributes to set
 */
-(void)setAttributeStore:(id <IAttributeStore>)values;

/**
 * Return the value for a given attribute.
 * @param name the name of the attribute to get
 * @return the attribute value or null if the attribute doesn't exist
 */
-(id)getAttribute:(NSString *)name;

/**
 * Return the value for a given attribute and set it if it doesn't exist.
 * 
 * <p>
 * This is a utility function that internally performs the following code:
 * <p>
 * <code>
 * if (!hasAttribute(name)) setAttribute(name, defaultValue);<br>
 * return getAttribute(name);<br>
 * </code>
 * </p>
 * </p>
 * 
 * @param name
 *            the name of the attribute to get
 * @param defaultValue
 *            the value of the attribute to set if the attribute doesn't
 *            exist
 * @return the attribute value
 */
-(id)getAttribute:(NSString *)name object:(id)defaultValue;

/**
 * Check the object has an attribute
 * @param name the name of the attribute to check
 * @return true if the attribute exists otherwise false
 */
-(BOOL)hasAttribute:(NSString *)name;

/**
 * Removes an attribute
 * @param name the name of the attribute to remove
 * @return true if the attribute was found and removed otherwise false
 */
-(BOOL)removeAttribute:(NSString *)name;

/**
 * Remove all attributes
 */
-(void)removeAttributes;


@end
