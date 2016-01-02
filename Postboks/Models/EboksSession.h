//
//  Created by Ole Gammelgaard Poulsen on 15/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EboksAccount;


@interface EboksSession : NSObject

@property(nonatomic, strong) EboksAccount *account;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *internalUserId;
@property(nonatomic, copy) NSString *deviceId;
@property(nonatomic, copy) NSString *sessionId;
@property(nonatomic, copy) NSString *nonce;

@end