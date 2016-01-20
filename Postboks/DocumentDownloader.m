//
//  Created by Ole Gammelgaard Poulsen on 16/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "DocumentDownloader.h"
#import "RACSignal.h"
#import "EboksSession.h"
#import "EboksAccount.h"
#import "APIClient.h"
#import "NSArray+RACSequenceAdditions.h"
#import "MessageInfo.h"
#import "NSArray+F.h"
#import "SettingsManager.h"
#import "EboksFolderInfo.h"
#import <ReactiveCocoa/ReactiveCocoa.h>


static const int MaxNotificationDocuments = 7;
static const int MaxNotificationPathLength = 90;


@interface DocumentDownloader ()
@end

@implementation DocumentDownloader {

}

- (instancetype)initWithAccount:(EboksAccount *)account {
	self = [super init];
	if (self) {
		NSAssert(account, @"Must have account");
		_account = account;
	}
	return self;
}

- (RACSignal *)downloadNewDocumentsAndNotifyUser {
	EboksAccount *account = self.account;
	NSLog(@"Starting download for user %@", account.userId);
	return [[[APIClient sharedInstanceForAccount:account] getSessionForAccount:account] flattenMap:^RACStream *(EboksSession *session) {
		return [[[self downloadInboxDocumentsWithSession:session] doNext:^(RACTuple *tuple) {
			RACTupleUnpack(NSArray *newlyDownloadedMessages, NSArray *failedToDownloadedMessages) = tuple;
			NSLog(@"newlyDownloadedMessages = %@", [newlyDownloadedMessages description]);
			NSLog(@"failedToDownloadedMessages = %@", [failedToDownloadedMessages description]);
			[self notifyUserAboutNewMessage:newlyDownloadedMessages userId:account.userId];
			[self notifyUserAboutFailedMessage:failedToDownloadedMessages];
		}] doCompleted:^{
			NSLog(@"Completed downloading for %@", account.userId);
		}];
	}];
}

+ (NSString *)baseDownloadPathForUserId:(NSString *)userId {
	return [[[SettingsManager sharedInstance] documentsBasePath] stringByAppendingPathComponent:userId];
}


- (RACSignal *)downloadInboxDocumentsWithSession:(EboksSession *)session {
	APIClient *api = [APIClient sharedInstanceForAccount:self.account];

	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableArray *newlyDownloadedMessages = [NSMutableArray array];
	NSMutableArray *failedToDownloadedMessages = [NSMutableArray array];

	RACSignal *getFoldersSignal = [api getFoldersWithSessionId:session];
	return [[[[getFoldersSignal flattenMap:^RACStream *(NSArray *folders) {
		NSArray *allFolderIds = [folders reduce:^id(NSArray *memo, EboksFolderInfo *folder) {
			return [memo arrayByAddingObjectsFromArray:[folder folderIdsIncludingSubfolders]];
		} withInitialMemo:@[]];
		NSArray *getFolderMessagesSignals = [allFolderIds map:^id(NSString *folderId) {
			RACSignal *getFolderContentsSignal = [api getFolderId:folderId session:session skip:0 take:100000];
			return [getFolderContentsSignal flattenMap:^RACStream *(NSArray *messages) {
				NSArray *downloadMessageSignal = [messages map:^id(MessageInfo *message) {
					NSString *filePath = [message fullFilePath];
					if ([fm fileExistsAtPath:filePath]) return [RACSignal return:message];
					[self createFolder:[message folderPath]];
					return [[[[[api getFileDataForMessageId:message.messageId session:session] doNext:^(NSData *fileData) {
						[fileData writeToFile:filePath atomically:YES];
						[newlyDownloadedMessages addObject:message];
					}] doError:^(NSError *error) {
						[failedToDownloadedMessages addObject:message];
					}] mapReplace:message] catch:^RACSignal *(NSError *error) {
						return [RACSignal return:message];
					}];
				}];
				return [RACSignal concat:downloadMessageSignal];
			}];
		}];
		return [RACSignal concat:getFolderMessagesSignals];
	}] ignoreValues] materialize] flattenMap:^RACStream *(RACEvent *event) {
		if (event.eventType == RACEventTypeError) return [RACSignal error:event.error];
		return [RACSignal return:RACTuplePack(newlyDownloadedMessages, failedToDownloadedMessages)];
	}];
}

- (void)createFolder:(NSString *)folderPath {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	[fm createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
	if (error) {
		NSLog(@"error creating directory: %@", [error localizedDescription]);
	}
}

#pragma mark - Notifications

- (void)notifyUserAboutNewMessage:(NSArray *)messages userId:(NSString *)userId {
	if (messages.count == 0) return;
	NSUserNotification *notification = [NSUserNotification new];
	NSString *title = [NSString stringWithFormat:@"%ld new eBoks messages", messages.count];
	NSString *subtitle = nil;
	if (messages.count == 1) {
		MessageInfo *message = messages.firstObject;
		title = message.name;
		subtitle = [NSString stringWithFormat:@"New message from %@", message.senderName];
	}
	notification.title = title;
	if (subtitle) {
		notification.subtitle = subtitle;
	}
	notification.actionButtonTitle = @"Open";
	notification.hasActionButton = YES;
	notification.soundName = NSUserNotificationDefaultSoundName;
	NSArray *filePaths = [messages map:^id(MessageInfo *message) {
		return [message filePathRelativeToBasePath];
	}];

	NSArray *folderPaths = [filePaths map:^id(NSString *path) {
		NSArray *pathComponents = [path pathComponents];
		NSString *folderPath = [[[pathComponents arrayUntilIndex:pathComponents.count - 1] componentsJoinedByString:@"/"] substringFromIndex:1];
		return folderPath;
	}];
	NSArray *uniqueuFolders = [[NSSet setWithArray:folderPaths] allObjects];

	// filter out long paths to avoid 1k limit
	if (filePaths.count > 1) {
		filePaths = [filePaths filter:^BOOL(NSString *path) {
			return path.length < MaxNotificationPathLength;
		}];
	}
	if (filePaths.count > MaxNotificationDocuments) {
		filePaths = [filePaths arrayUntilIndex:MaxNotificationDocuments - 1];
	}
	notification.userInfo = @{
			NotificationKeyPdfPaths : filePaths,
			NotificationKeyUserId : userId,
			NotificationKeyNumFiles : @(messages.count),
			NotificationKeyNumFolders : @(uniqueuFolders.count),
	};

	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)notifyUserAboutFailedMessage:(NSArray *)messages {
	if (messages.count == 0) return;
	NSUserNotification *notification = [NSUserNotification new];
	if (messages.count == 1) {
		MessageInfo *message = messages.firstObject;
		notification.title = [NSString stringWithFormat:@"Failed to donload message '%@'", message.name];
	} else {
		notification.title = [NSString stringWithFormat:@"Failed to download %ld messages", messages.count];
	}
	notification.soundName = NSUserNotificationDefaultSoundName;
	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}


@end