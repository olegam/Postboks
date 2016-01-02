//
//  Created by Ole Gammelgaard Poulsen on 02/12/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "CenteredTextField.h"

@implementation CenteredTextField {

}

- (NSPoint)textOffsetForHeight:(CGFloat)textHeight
{
	// center vertically
	return NSMakePoint(12.0, round(NSMidY(self.bounds) - textHeight / 2));
}

- (CGFloat)textWidth
{
	// the size of our field minus the margin on both size
	return self.bounds.size.width - 12 * 2;
}

- (NSDictionary *)stringAttributes
{
	NSMutableDictionary *origAttrs = [super stringAttributes].mutableCopy;
	origAttrs[NSFontAttributeName] = [NSFont fontWithName:@"HelveticaNeue-Medium" size:16.0];
	origAttrs[NSForegroundColorAttributeName] = [NSColor colorWithWhite:89.f / 255.f alpha:1.f];
	return origAttrs;
}

- (CGFloat)minimumHeight {
	return 50;
}

- (CGFloat)maximumHeight {
	return [self minimumHeight];
}


@end