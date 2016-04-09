//
// Created by Ole Gammelgaard Poulsen on 09/04/16.
// Copyright (c) 2016 Ole Gammelgaard. All rights reserved.
//

#import "NotificationController.h"
#import "DocumentDownloader.h"
#import "NSArray+F.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

static const int MaxFilesToOpenInPreview = 4;
static const int MaxFoldersToOpen = 3;

@implementation NotificationController {

}

- (void)handleUserClickedOnNotification:(NSUserNotification *)notification {
	NSDictionary *userInfo = notification.userInfo;

	NSString *notificationIdentifier = userInfo[NotificationKeyIdentifier];
	if (!notificationIdentifier) return; // maybe created by an older version

	NSURL *fileURL = [self payloadURLForIdentifier:notificationIdentifier];
	if (!fileURL) return;
	NSDictionary *fullNotificationDict = [[NSDictionary alloc] initWithContentsOfURL:fileURL];
	if (!fullNotificationDict) return;

	NSString *userName = fullNotificationDict[NotificationKeyUserName];
	NSInteger numberOfFiles = [fullNotificationDict[NotificationKeyNumFiles] integerValue];
	NSInteger numberOfUniqueFolders = [fullNotificationDict[NotificationKeyNumFolders] integerValue];

	NSArray *relativePaths = fullNotificationDict[NotificationKeyPdfPaths];
	NSString *userBaseDownloadPath = [DocumentDownloader baseDownloadPathForName:userName];
	NSArray *pdfPaths = [relativePaths map:^id(NSString *relativeFilePath) {
		return [userBaseDownloadPath stringByAppendingPathComponent:relativeFilePath];
	}];
	if (numberOfFiles <= MaxFilesToOpenInPreview) {
		[pdfPaths each:^(NSString *path) {
			[[NSWorkspace sharedWorkspace] openFile:path];
		}];
	} else if (numberOfUniqueFolders <= MaxFoldersToOpen) {
		NSArray *urls = [pdfPaths map:^id(NSString *path) {
			return [[NSURL alloc] initFileURLWithPath:path];
		}];
		[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:urls];
	} else {
		[[NSWorkspace sharedWorkspace] openFile:userBaseDownloadPath];
	}
}

- (NSString *)saveNotificationUserInfo:(NSDictionary *)payload {
	NSAssert(payload, @"Must supply payload");
	NSString *identifier = [[NSUUID new] UUIDString];
	NSURL *url = [self payloadURLForIdentifier:identifier];
	if (!url) return nil;
	[payload writeToURL:url atomically:YES];
	return identifier;
}

- (NSURL *)payloadURLForIdentifier:(NSString *)identifier {
	NSURL *applicationSupportDataURL = [self applicationDataDirectory];
	if (!applicationSupportDataURL) return nil;
	NSString *fileName = [NSString stringWithFormat:@"notification_%@.plist", identifier];
	NSURL *fileURL = [applicationSupportDataURL URLByAppendingPathComponent:fileName];
	return fileURL;
}


- (NSURL *)applicationDataDirectory {
	NSFileManager* sharedFM = [NSFileManager defaultManager];
	NSArray* possibleURLs = [sharedFM URLsForDirectory:NSApplicationSupportDirectory
											 inDomains:NSUserDomainMask];
	NSURL* appSupportDir = possibleURLs.firstObject;
	NSURL* appDirectory = nil;

	if (appSupportDir) {
		NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
		appDirectory = [appSupportDir URLByAppendingPathComponent:appBundleID];

		if (![sharedFM fileExistsAtPath:appDirectory.path]) {
			[sharedFM createDirectoryAtURL:appDirectory withIntermediateDirectories:YES attributes:nil error:nil];
		}
	}

	return appDirectory;
}

@end