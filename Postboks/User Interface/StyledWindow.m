//
//  Created by Ole Gammelgaard Poulsen on 20/09/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <objc/runtime.h>
#import "StyledWindow.h"
#import "View+MASAdditions.h"

@interface StyledWindow ()
- (float)roundedCornerRadius;
- (void)drawRectOriginal:(NSRect)rect;
@end

@implementation StyledWindow {

}

- (id)initWithContentRect:(NSRect)contentRect {
	self = [super initWithContentRect:contentRect
							styleMask:NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask
							  backing:NSBackingStoreBuffered defer:NO];
	if (self) {
		// Swizzle draw rect
		id class = [[[self contentView] superview] class];
		Method m0 = class_getInstanceMethod([self class], @selector(drawRect:));
		class_addMethod(class, @selector(drawRectOriginal:), method_getImplementation(m0), method_getTypeEncoding(m0));
		Method m1 = class_getInstanceMethod(class, @selector(drawRect:));
		Method m2 = class_getInstanceMethod(class, @selector(drawRectOriginal:));
		method_exchangeImplementations(m1, m2);
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
	[self drawRectOriginal:rect];

	NSRect windowRect = [self frame];
	windowRect.origin = NSMakePoint(0, 0);

	float cornerRadius = [self roundedCornerRadius];
	[[NSBezierPath bezierPathWithRoundedRect:windowRect xRadius:cornerRadius yRadius:cornerRadius] addClip];
	[[NSBezierPath bezierPathWithRect:rect] addClip];

	[[NSColor colorWithWhite:236.f/255.f alpha:1] set];
	[[NSBezierPath bezierPathWithRect:rect] fill];


	NSRect titleRect = self.frame;
	titleRect.origin.y = titleRect.size.height - 20;
	titleRect.size.height = 40;
	NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	NSDictionary *attributes = @{
			NSParagraphStyleAttributeName : paragraphStyle,
			NSFontAttributeName : [NSFont fontWithName:@"HelveticaNeue-Bold" size:15],
			NSForegroundColorAttributeName : [NSColor colorWithWhite:0.25f alpha:0.8f],
	};
	[self.title drawWithRect:titleRect options:0 attributes:attributes];
}

- (BOOL)isMovableByWindowBackground {
	return YES;
}

- (BOOL)preservesContentDuringLiveResize {
	return NO;
}

@end