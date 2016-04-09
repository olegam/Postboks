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
#import "MigrationManager.h"
#import "NotificationController.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <Sparkle/Sparkle.h>


@interface AppDelegate () <NSUserNotificationCenterDelegate, SUUpdaterDelegate>

@property (nonatomic, strong) StatusBarController *statusBarController;
@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
	[Fabric with:@[[Crashlytics class]]];
	
	[[SUUpdater sharedUpdater] installUpdatesIfAvailable];
	
	self.appBundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	self.appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	
	self.statusBarController = [StatusBarController new];

	[NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;

	[[MigrationManager sharedInstance] performMigrations];

	[SyncScheduler sharedInstance]; // starts syncing immediately and every xx interval
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {

}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
	[center removeDeliveredNotification:notification];
	NotificationController *notificationController = [NotificationController new];
	[notificationController handleUserClickedOnNotification:notification];
}

@end
