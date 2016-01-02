//
//  Created by Ole Gammelgaard Poulsen on 21/09/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "TabButton.h"

@interface TabButton ()
@property(nonatomic, strong) NSImage *icon;
@end

@implementation TabButton {

}

- (id)init {
	NSAssert(NO, @"Must use designated initializer");
	return nil;
}

- (id)initWithTitle:(NSString *)title icon:(NSImage *)icon {
	self = [super init];
	if (self) {
		_icon = icon;

		[self setBordered:NO];
		[self setTitle:title];
	}
	return self;
}

- (void)setSelectedTab:(BOOL)selectedTab {
	_selectedTab = selectedTab;
	[self setNeedsDisplay];
}

- (BOOL)acceptsFirstResponder {
	return NO;
}

- (void)drawRect:(NSRect)dirtyRect {
	CGRect bounds = [self frame];
	bounds.origin.x = 0;
	bounds.origin.y = 0;

	[[NSColor colorWithWhite:.2f alpha:1] set];

	if (self.selectedTab) {
		NSImage *backgroundImage = [NSImage imageNamed:@"selected_tab_background"];
		CGRect backgroundImageRect = bounds;
		backgroundImageRect.size = backgroundImage.size;
		[backgroundImage drawInRect:backgroundImageRect fromRect:NSZeroRect operation:NSCompositeSourceOver
						   fraction:1.0f respectFlipped:YES hints:nil];
	}

	if (self.icon) {
		CGRect iconImageRect = bounds;
		iconImageRect.size = self.icon.size;
		iconImageRect.origin.x = (bounds.size.width - iconImageRect.size.width) / 2.f;
		iconImageRect.origin.y = 8;
		[self.icon drawInRect:iconImageRect fromRect:NSZeroRect operation:NSCompositeSourceOver
						   fraction:1.0f respectFlipped:YES hints:nil];
	}

	if (self.title) {
		NSRect titleRect = bounds;
		titleRect.origin.y = titleRect.size.height - 8;
		titleRect.size.height = 18;
		NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		NSDictionary *attributes = @{
				NSParagraphStyleAttributeName : paragraphStyle,
				NSFontAttributeName : [NSFont fontWithName:@"HelveticaNeue" size:11],
				NSForegroundColorAttributeName : [NSColor colorWithWhite:0.25f alpha:0.8f],
		};
		[self.title drawWithRect:titleRect options:0 attributes:attributes];
	}
}

@end