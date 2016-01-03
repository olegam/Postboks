//
//  AppDelegate.m
//  EboksSync
//
//  Created by Ole Gammelgaard Poulsen on 11/08/14.
//  Copyright (c) 2014 Ole Gammelgaard. All rights reserved.
//

#import "AppDelegate.h"
#import <CocoaSecurity/CocoaSecurity.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "APIClient.h"
#import "EboksAccount.h"
#import "EboksSession.h"
#import "MessageInfo.h"
#import "DocumentDownloader.h"
#import "NSArray+F.h"
#import "SettingsManager.h"
#import "SyncScheduler.h"
#import "StatusBarController.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <Sparkle/Sparkle.h>


static const int MaxFilesToOpenInPreview = 4;
static const int MaxFoldersToOpen = 3;

@interface AppDelegate () <NSUserNotificationCenterDelegate, SUUpdaterDelegate>

@property (nonatomic, strong) StatusBarController *statusBarController;
@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
	[Fabric with:@[[Crashlytics class]]];
	
	[[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:YES];
	[[SUUpdater sharedUpdater] setAutomaticallyDownloadsUpdates:YES];
	[[SUUpdater sharedUpdater] checkForUpdates:nil];
	
	self.appBundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	self.appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	
	self.statusBarController = [StatusBarController new];

	[NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;

	[SyncScheduler sharedInstance]; // starts syncing immediately and every xx interval
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {

}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
	[center removeDeliveredNotification:notification];
	NSDictionary *userInfo = notification.userInfo;
	NSString *userId = userInfo[NotificationKeyUserId];
	NSInteger numberOfFiles = [userInfo[NotificationKeyNumFiles] integerValue];
	NSInteger numberOfUniqueFolders = [userInfo[NotificationKeyNumFolders] integerValue];

	NSArray *relativePaths = userInfo[NotificationKeyPdfPaths];
	NSString *userBaseDownloadPath = [DocumentDownloader baseDownloadPathForUserId:userId];
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

@end
