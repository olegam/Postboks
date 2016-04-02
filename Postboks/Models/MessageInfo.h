//
//  Created by Ole Gammelgaard Poulsen on 15/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ono/ONOXMLDocument.h>

@class AttachmentInfo;

@interface MessageInfo : NSObject


@property(nonatomic, strong) NSString *messageId;
@property(nonatomic, strong) NSString *senderName;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, strong) NSDate *receivedDate;
@property(nonatomic, strong) NSString *folderId;
@property(nonatomic, assign) BOOL unread;
@property(nonatomic, copy) NSString *lastAction;
@property(nonatomic, strong) NSString *userName;
@property(nonatomic, strong) NSString *fileFormat;

@property(nonatomic, assign) NSUInteger numAttachments;

@property(nonatomic, strong) NSArray *attachments;

+ (instancetype)messageFromXMLElement:(ONOXMLElement *)element name:(NSString *)name;

+ (NSString *)sanitizeFileNameString:(NSString *)fileName;

- (NSString *)fileName;

- (NSString *)folderPath;

- (NSString *)filePathRelativeToBasePath;

- (NSString *)fullFilePath;

- (NSString *)fullFilePathForAttachment:(AttachmentInfo *)attachment;

- (NSString *)filePathRelativeToBasePathForAttachment:(AttachmentInfo *)attachment;
@end