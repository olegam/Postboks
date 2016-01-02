//
//  Created by Ole Gammelgaard Poulsen on 02/10/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "BasePreferencesView.h"
#import "SidebarView.h"
#import "BackgroundColorView.h"
#import <Masonry/Masonry.h>

@implementation BasePreferencesView {

}

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		self.sidebarView = [SidebarView new];
		[self addSubview:self.sidebarView];

		self.contentView = [BackgroundColorView new];
		self.contentView.backgroundColor = [NSColor colorWithDeviceRed:241.f / 255.f green:239.f / 255.f blue:239.f / 255.f alpha:2.f];
		self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview:self.contentView];
	}
	return self;
}

- (void)updateConstraints {
	[super updateConstraints];

	[self.sidebarView mas_updateConstraints:^(MASConstraintMaker *make) {
		make.top.left.bottom.equalTo(self);
		make.width.equalTo(@150.f);
	}];

	[self.contentView mas_updateConstraints:^(MASConstraintMaker *make) {
		make.top.right.bottom.equalTo(self);
		make.left.equalTo(self.sidebarView.mas_right);
	}];
}


@end