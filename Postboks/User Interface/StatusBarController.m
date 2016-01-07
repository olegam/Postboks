//
//  Created by Ole Gammelgaard Poulsen on 17/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "StatusBarController.h"
#import "SyncScheduler.h"
#import "SettingsManager.h"
#import "PreferencesWindowController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>


@interface StatusBarController ()
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenuItem *lastSyncMenuItem;
@property (nonatomic, strong) NSMenuItem *syncNowMenuItem;
@property (nonatomic, strong) NSMenuItem *openFolderMenuItem;
@property(nonatomic, strong) PreferencesWindowController *preferencesWindowController;

@property(nonatomic, strong) SyncScheduler *syncScheduler;
@end

@implementation StatusBarController {

}

- (instancetype)init {
	self = [super init];
	if (self) {
		[self setupMenu];
		_syncScheduler = [SyncScheduler sharedInstance];

		RAC(self, lastSyncMenuItem.title) = RACObserve(self.syncScheduler, nextSyncDescription);
		[self.syncNowMenuItem rac_liftSelector:@selector(setEnabled:) withSignalsFromArray:@[[RACObserve(self.syncScheduler, syncing) not]]];
		RAC(self.syncNowMenuItem, title) = [RACObserve(self.syncScheduler, syncing) map:^id(NSNumber *syncingNum) {
			return [syncingNum boolValue] ? NSLocalizedString(@"status-syncing", @"Syncing...") : NSLocalizedString(@"sync-now", @"Sync now");
		}];

		if ([[SettingsManager sharedInstance] accounts].count == 0) {
			[self showPreferences:nil];
		}
	}
	return self;
}

- (void)setupMenu
{
	self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
	self.statusItem.image = [NSImage imageNamed:@"menubar_icon"];
	self.statusItem.alternateImage = [NSImage imageNamed:@"menubar_icon_selected"];
	self.statusItem.title = @"";
	self.statusItem.highlightMode = YES;
    [self.statusItem.image setTemplate:YES];

	NSMenu *menu = [NSMenu new];
	[menu setAutoenablesItems:NO];

	[menu addItem:self.lastSyncMenuItem];

	[menu addItem:[NSMenuItem separatorItem]];
	self.syncNowMenuItem = [menu addItemWithTitle:@"_" action:@selector(syncNowClicked:) keyEquivalent:@""];
	[self.syncNowMenuItem setTarget:self];

	self.openFolderMenuItem = [menu addItemWithTitle:NSLocalizedString(@"open-documents-folder", @"Open documents folder") action:@selector(openDocuments) keyEquivalent:@""];
	[self.openFolderMenuItem setTarget:self];

	[menu addItem:[NSMenuItem separatorItem]];
	[[menu addItemWithTitle:NSLocalizedString(@"preferences-open", @"Preferences...") action:@selector(showPreferences:) keyEquivalent:@""] setTarget:self];

	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:NSLocalizedString(@"quit", @"Quit") action:@selector(terminate:) keyEquivalent:@""];

	self.statusItem.menu = menu;
}

- (void)showPreferences:(id)sender {
	[self.preferencesWindowController showWindow:nil];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)syncNowClicked:(id)sender {
	[_syncScheduler startSync:YES];
}

- (void)openDocuments {
	NSString *basePath = [[SettingsManager sharedInstance] documentsBasePath];
	[[NSWorkspace sharedWorkspace] openFile:basePath];
}

#pragma mark - Lazy loaded

- (NSMenuItem *)lastSyncMenuItem {
	if (!_lastSyncMenuItem) {
		_lastSyncMenuItem = [NSMenuItem new];
	}
	return _lastSyncMenuItem;
}

- (PreferencesWindowController *)preferencesWindowController {
	if (!_preferencesWindowController) {
		_preferencesWindowController = [PreferencesWindowController new];
		[_preferencesWindowController.window setLevel:NSFloatingWindowLevel];
	}
	return _preferencesWindowController;
}


@end