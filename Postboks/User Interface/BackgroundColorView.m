//
//  Created by Ole Gammelgaard Poulsen on 02/10/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "BackgroundColorView.h"

@implementation BackgroundColorView {

}



- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];

	if (self.backgroundColor) {
		[self.backgroundColor set];
		[[NSBezierPath bezierPathWithRect:dirtyRect] fill];
	}
}

@end