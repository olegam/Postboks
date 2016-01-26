//
// Created by Ole Gammelgaard Poulsen on 26/01/16.
// Copyright (c) 2016 Ole Gammelgaard. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ONOXMLElement;


@interface AttachmentInfo : NSObject

@property(nonatomic, strong) NSString *attachmentId;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSString *fileFormat;

+ (instancetype)attachmentFromXMLElement:(ONOXMLElement *)element;
@end