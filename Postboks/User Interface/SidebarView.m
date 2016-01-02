//
//  Created by Ole Gammelgaard Poulsen on 02/10/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Masonry/View+MASAdditions.h>
#import "SidebarView.h"
#import "NSDictionary+F.h"

static const float SidebarViewRightFillWidth = 4.f;
static const float SidebarViewLineWidth = 0.5f;

@interface SidebarView ()
@property(nonatomic, strong) NSArray *titleViews;
@end

@implementation SidebarView {

}

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		self.translatesAutoresizingMaskIntoConstraints = NO;
	}
	return self;
}

- (void)setTitlesAtPositions:(NSDictionary *)titlesPositions {
	_titlesAtPositions = titlesPositions;
	for (NSView *titleView in self.titleViews) {
		[titleView removeFromSuperview];
	}

	self.titleViews = [[titlesPositions map:^id(NSString *title, NSNumber *topOffsetNum) {
		NSTextField *titleView = [NSTextField new];
		[titleView setBezeled:NO];
		[titleView setDrawsBackground:NO];
		[titleView setEditable:NO];
		[titleView setSelectable:NO];
		[titleView setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:14]];
		[titleView setTextColor:[NSColor colorWithWhite:89.f/255.f alpha:1.f]];
		[titleView setStringValue:title];
		[titleView setAlignment:NSRightTextAlignment];

		[self addSubview:titleView];
		[titleView mas_updateConstraints:^(MASConstraintMaker *make) {
			make.left.equalTo(titleView.superview).offset(16);
			make.right.equalTo(titleView.superview).offset(-16);
			make.height.equalTo(@30.f);
			make.top.equalTo(titleView.superview).offset([topOffsetNum floatValue]);
		}];

		return titleView;
	}] allValues];
}

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];

	[[NSColor colorWithWhite:249.f / 255.f alpha:1.f] set];
	[[NSBezierPath bezierPathWithRect:self.frame] fill];


	CGRect rightFillRect = CGRectZero;
	CGRect remainderRect = CGRectZero;
	CGRectDivide(self.frame, &remainderRect, &rightFillRect, self.frame.size.width - SidebarViewRightFillWidth, CGRectMinXEdge);
	[[NSColor colorWithWhite:236.f / 255.f alpha:1.f] set];
	[[NSBezierPath bezierPathWithRect:rightFillRect] fill];

	CGRect firstLineRect = rightFillRect;
	firstLineRect.size.width = SidebarViewLineWidth;
	[[NSColor colorWithWhite:218.f / 255.f alpha:1.f] set];
	[[NSBezierPath bezierPathWithRect:firstLineRect] fill];

	CGRect secondLineRect = firstLineRect;
	secondLineRect.origin.x += SidebarViewRightFillWidth - SidebarViewLineWidth;
	[[NSBezierPath bezierPathWithRect:secondLineRect] fill];
}

@end