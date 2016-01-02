//
//  Created by Ole Gammelgaard Poulsen on 20/09/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TabBarView.h"
#import "View+MASAdditions.h"
#import "TabButton.h"

@interface TabBarView ()
@property(nonatomic, strong) NSArray *buttons;
@end

@implementation TabBarView {

}

- (id)init {
	NSAssert(NO, @"Must use designated initializer");
	return nil;
}

- (instancetype)initWithButtons:(NSArray *)buttons {
	self = [super init];
	if (self) {
		self.buttons = buttons;

		// add buttons
		for (NSButton *button in buttons) {
			[self addSubview:button];
		}

		// setup layout constraints
		id leftAttribute = self.mas_left;
		for (NSButton *button in buttons) {
			CGFloat leftMargin = button == buttons.firstObject ? 10 : 6;
			[button mas_updateConstraints:^(MASConstraintMaker *make) {
				make.top.equalTo(self).offset(4);
				make.bottom.equalTo(self).offset(0);
				make.left.equalTo(leftAttribute).offset(leftMargin);
				make.width.equalTo(@70);
			}];
			leftAttribute = button.mas_right;
		}

		// set target-action
		for (NSButton *button in buttons) {
			[button setTarget:self];
			[button setAction:@selector(tabButtonClicked:)];
		}

		[buttons.firstObject setSelectedTab:YES];
	}
	return self;
}

- (void)tabButtonClicked:(NSButton *)buttonClicked {
	self.selectedIndex = [self.buttons indexOfObject:buttonClicked];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
	NSAssert(selectedIndex < self.buttons.count, @"selectedIndex out of range (%ld)", self.buttons.count);
	_selectedIndex = selectedIndex;
	TabButton *button = self.buttons[(NSUInteger) selectedIndex];
	for (TabButton *btn in self.buttons) {
		[btn setSelectedTab:button == btn];
	}
}


- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];

	CGRect bottomLineRect = self.frame;
	bottomLineRect.size.height = 0.5f;
	bottomLineRect.origin.y = 0;//bottomLineRect.size.height;
	[[NSColor colorWithWhite:.86f alpha:1] set];
	[[NSBezierPath bezierPathWithRect:bottomLineRect] fill];
}


@end