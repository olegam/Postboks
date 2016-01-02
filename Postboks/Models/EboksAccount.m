//
//  Created by Ole Gammelgaard Poulsen on 15/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "EboksAccount.h"

@implementation EboksAccount {

}

- (NSString *)maskedUserId {
	return [NSString stringWithFormat:@"%@-xxxx", [self.userId substringToIndex:6]];
}


@end