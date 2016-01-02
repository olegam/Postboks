//
//  Created by Ole Gammelgaard Poulsen on 15/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EboksAccount : NSObject

@property(nonatomic, copy) NSString *userId;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, copy) NSString *activationCode;
@property(nonatomic, copy) NSString *ownerName;
@property(nonatomic, assign) BOOL failedLoading;


- (NSString *)maskedUserId;
@end