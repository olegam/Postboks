//
//  Created by Ole Gammelgaard Poulsen on 15/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "EboksAccount.h"

NSString * const EboksNationalityDenmark = @"DK";
NSString * const EboksNationalitySweden = @"SE";

@implementation EboksAccount {

}

- (NSString *)maskedUserId {
  NSRange dateRange = NSMakeRange(self.userId.length - 4, 4);
  return [self.userId stringByReplacingCharactersInRange:dateRange withString:@"-xxxx"];
}

- (NSString *)nationality {
  return _nationality ? [_nationality copy] : EboksNationalityDenmark;
}

@end