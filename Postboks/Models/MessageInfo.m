//
//  Created by Ole Gammelgaard Poulsen on 15/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Ono/ONOXMLDocument.h>
#import "MessageInfo.h"
#import "AppDelegate.h"
#import "DocumentDownloader.h"
#import "AttachmentInfo.h"
#import <ISO8601DateFormatter/ISO8601DateFormatter.h>
#import <Functional.m/NSArray+F.h>

@implementation MessageInfo {

}

+ (instancetype)messageFromXMLElement:(ONOXMLElement *)element name:(NSString *)name {
	MessageInfo *message = [MessageInfo new];

	message.messageId = [element valueForAttribute:@"id"];
	message.senderName = [element firstChildWithTag:@"Sender"].stringValue;
	message.name = [element valueForAttribute:@"name"];
	message.folderId = [element valueForAttribute:@"folderId"];
	message.lastAction = [element valueForAttribute:@"lastAction"];
	message.unread = [[element valueForAttribute:@"unread"] isEqualTo:@"true"];
	NSString *dateString = [element valueForAttribute:@"receivedDateTime"];
	message.receivedDate = [[MessageInfo dateParsingFormatter] dateFromString:dateString];
	message.userName = name;
	message.fileFormat = [[element valueForAttribute:@"format"] lowercaseString];

	NSArray *attachmentElements = [[element firstChildWithTag:@"Attachements"] childrenWithTag:@"AttachmentInfo"];
	if (attachmentElements.count == 0) {
		message.numAttachments = (NSUInteger) [[element valueForAttribute:@"attachmentsCount"] integerValue];
		message.attachments = @[];
	} else {
		message.attachments = [attachmentElements map:^id(ONOXMLElement *attachmentElement) {
			return [AttachmentInfo attachmentFromXMLElement:attachmentElement];
		}];
		message.numAttachments = message.attachments.count;
	}

	return message;
}

- (NSString *)fileName {
	NSString *unEscapedName = [NSString stringWithFormat:@"%@ (%@).%@", self.name, self.senderName, self.fileFormat];
	NSString *safeName = [MessageInfo sanitizeFileNameString:unEscapedName];
	return safeName;
}

- (NSString *)folderPathrelativeToBasePath {
	NSString *dateString = [[MessageInfo simpleDateFormatter] stringFromDate:self.receivedDate];
	return dateString;
}

- (NSString *)folderPath {
	NSString *basePath = [DocumentDownloader baseDownloadPathForName:self.userName];
	NSString *fullPath = [basePath  stringByAppendingPathComponent:[self folderPathrelativeToBasePath]];
	return fullPath;
}

- (NSString *)filePathRelativeToBasePath {
	return [[self folderPathrelativeToBasePath] stringByAppendingPathComponent:[self fileName]];
}

- (NSString *)fullFilePath {
	return [[self folderPath] stringByAppendingPathComponent:[self fileName]];
}

- (NSString *)fullFilePathForAttachment:(AttachmentInfo *)attachment {
	NSString *safeName = [self fileNameForAttachment:attachment];
	return [[self folderPath] stringByAppendingPathComponent:safeName];
}

- (NSString *)filePathRelativeToBasePathForAttachment:(AttachmentInfo *)attachment {
	return [[self folderPathrelativeToBasePath] stringByAppendingPathComponent:[self fileNameForAttachment:attachment]];
}

- (NSString *)fileNameForAttachment:(AttachmentInfo *)attachment {
	NSString *unEscapedName = [NSString stringWithFormat:@"%@ (%@) - %@.%@", self.name, self.senderName, attachment.name, attachment.fileFormat];
	NSString *safeName = [MessageInfo sanitizeFileNameString:unEscapedName];
	return safeName;
}

#pragma mark - Helpers

+ (NSString *)sanitizeFileNameString:(NSString *)fileName {
	NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>:"];
	return [[fileName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
}

+ (ISO8601DateFormatter *)dateParsingFormatter {
	NSString *cacheKey = [NSString stringWithFormat:@"DateParsingFormatter-%@", NSStringFromClass([self class])];
	NSMutableDictionary *cache = [[NSThread currentThread] threadDictionary];
	ISO8601DateFormatter *dateFormatter = cache[cacheKey];
	if (!dateFormatter) {
		dateFormatter = [ISO8601DateFormatter new];
		cache[cacheKey] = dateFormatter;
	}
	return dateFormatter;
}

+ (NSDateFormatter *)simpleDateFormatter {
	NSString *cacheKey = [NSString stringWithFormat:@"SimpleDateFormatter-%@", NSStringFromClass([self class])];
	NSMutableDictionary *cache = [[NSThread currentThread] threadDictionary];
	NSDateFormatter *dateFormatter = cache[cacheKey];
	if (!dateFormatter) {
		dateFormatter = [NSDateFormatter new];
		dateFormatter.dateFormat = @"yyyy-MM";
		cache[cacheKey] = dateFormatter;
	}
	return dateFormatter;
}

@end