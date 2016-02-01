//
// Created by Ole Gammelgaard Poulsen on 26/01/16.
// Copyright (c) 2016 Ole Gammelgaard. All rights reserved.
//

#import "AttachmentInfo.h"
#import "ONOXMLDocument.h"
#import <Ono/ONOXMLDocument.h>

@implementation AttachmentInfo {

}

+ (instancetype)attachmentFromXMLElement:(ONOXMLElement *)element {
	AttachmentInfo *attachment = [AttachmentInfo new];

	attachment.attachmentId = [element valueForAttribute:@"id"];
	attachment.name = [element valueForAttribute:@"name"];
	attachment.fileFormat = [element valueForAttribute:@"format"];

	return attachment;
}

@end