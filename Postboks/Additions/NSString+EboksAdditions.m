//
//  Created by Ole Gammelgaard Poulsen on 15/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "NSString+EboksAdditions.h"

@implementation NSString (EboksAdditions)

+ (NSString *)nextUUID {
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	__autoreleasing NSString *returnString = (__bridge NSString *)string;
	return returnString;
}

@end