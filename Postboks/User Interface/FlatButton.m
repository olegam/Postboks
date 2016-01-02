//
//  Created by Ole Gammelgaard Poulsen on 02/10/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "FlatButton.h"
#import "NSButton+RACAdditions.h"

@implementation FlatButton {

}

- (id)init {
	self = [super init];
	if (self) {

	}
	return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	CGRect bounds = [self frame];
	bounds.origin.x = 0;
	bounds.origin.y = 0;

	NSColor *backgroundColor = [NSColor colorWithWhite:0.95f alpha:1.f];
	[backgroundColor set];
	[[NSBezierPath bezierPathWithRoundedRect:bounds xRadius:4.f yRadius:4.f] fill];

	if (self.title) {
		NSRect titleRect = CGRectInset(bounds, 10, 5);
		titleRect.origin.y = titleRect.size.height - 2;
		NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		NSDictionary *attributes = @{
				NSParagraphStyleAttributeName : paragraphStyle,
				NSFontAttributeName : [NSFont fontWithName:@"HelveticaNeue-Medium" size:14],
				NSForegroundColorAttributeName : [NSColor colorWithWhite:.35 alpha:1.f],
		};
		[self.title drawWithRect:titleRect options:0 attributes:attributes];
	}
}


@end