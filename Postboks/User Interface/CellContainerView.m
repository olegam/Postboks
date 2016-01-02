//
//  Created by Ole Gammelgaard Poulsen on 02/10/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "CellContainerView.h"
#import "BackgroundColorView.h"
#import <Masonry/Masonry.h>

@interface CellContainerView ()
@property(nonatomic, strong) NSArray *dividerViews;
@end

@implementation CellContainerView {

}

- (id)initWithFrame:(NSRect)frameRect {
	NSAssert(NO, @"Must use designated initializer");
	return nil;
}

- (id)init {
	NSAssert(NO, @"Must use designated initializer");
	return nil;
}

- (id)initWithNumberOfContainers:(NSUInteger)numContainers {
	self = [super initWithFrame:CGRectZero];
	if (self) {
		NSAssert(numContainers > 0, @"numContainers must be > 0");
		self.translatesAutoresizingMaskIntoConstraints = NO;

		NSMutableArray *containers = [NSMutableArray array];
		NSMutableArray *dividers = [NSMutableArray array];
		for (NSUInteger containerIndex = 0; containerIndex < numContainers; containerIndex++) {
			BackgroundColorView *c = [BackgroundColorView new];
			c.backgroundColor = [NSColor whiteColor];
			c.translatesAutoresizingMaskIntoConstraints = NO;
			[containers addObject:c];
			[self addSubview:c];

			if (containerIndex < numContainers - 1) {
				BackgroundColorView *d = [BackgroundColorView new];
				d.backgroundColor = [NSColor colorWithWhite:224.f / 255.f alpha:1.f];
				d.translatesAutoresizingMaskIntoConstraints = NO;
				[dividers addObject:d];
				[self addSubview:d];
			}
		}

		_containerViews = [containers copy];
		_dividerViews = [dividers copy];
	}
	return self;
}

- (void)updateConstraints {
	[super updateConstraints];

	id currentTopAttribute = self.mas_top;
	for (NSUInteger containerIndex = 0; containerIndex < self.containerViews.count; containerIndex++) {
		NSView *container = self.containerViews[containerIndex];
		[container mas_updateConstraints:^(MASConstraintMaker *make) {
			make.left.right.equalTo(self);
			make.top.equalTo(currentTopAttribute);
			make.height.equalTo(@58);
		}];
		currentTopAttribute = container.mas_bottom;

		if (containerIndex < self.containerViews.count - 1) {
			NSView *divider = self.dividerViews[containerIndex];
			[divider mas_updateConstraints:^(MASConstraintMaker *make) {
				make.left.right.equalTo(self);
				make.top.equalTo(currentTopAttribute);
				make.height.equalTo(@0.5f);
			}];
			currentTopAttribute = divider.mas_bottom;
		}
	}


}


@end