//
// Created by Ole Gammelgaard Poulsen on 02/02/16.
// Copyright (c) 2016 Ole Gammelgaard. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ONOXMLElement;


@interface SharedAccount : NSObject

@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *userId;

+ (id)shareFromXMLElement:(ONOXMLElement *)element;

@end