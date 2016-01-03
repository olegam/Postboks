//
//  Created by Ole Gammelgaard Poulsen on 02/10/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Masonry/View+MASAdditions.h>
#import <Functional.m/NSArray+F.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "ModernGeneralPreferencesViewController.h"
#import "BasePreferencesView.h"
#import "SidebarView.h"
#import "CellContainerView.h"
#import "BackgroundColorView.h"
#import "FlatButton.h"
#import "SettingsManager.h"
#import "SyncScheduler.h"
#import "NSButton+RACAdditions.h"


@interface ModernGeneralPreferencesViewController ()
@property(nonatomic, strong) BasePreferencesView *basePreferencesView;
@property(nonatomic, strong) CellContainerView *cellContainerView;

@property (nonatomic, strong) NSButton *startAtLaunchSwitchButton;
@property (nonatomic, strong) NSTextField *downloadsFolderValueLabel;
@property(nonatomic, strong) FlatButton *changeDownloadFolderButton;

@property (nonatomic, strong) NSTextField *versionLabel;

@end

@implementation ModernGeneralPreferencesViewController {

}

- (instancetype)init {
	self = [super init];
	if (self) {
		self.basePreferencesView = [BasePreferencesView new];
		[self setView:self.basePreferencesView];

		[self.basePreferencesView.sidebarView setTitlesAtPositions:@{
				NSLocalizedString(@"launch-sidebar-title", @"Launch") : @34,
				NSLocalizedString(@"download-folder-sidebar-title", @"Download folder") : @91,
		}];

		self.cellContainerView = [[CellContainerView alloc] initWithNumberOfContainers:2];
		[self.basePreferencesView.contentView addSubview:self.cellContainerView];

		[self.cellContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
			make.left.bottom.right.equalTo(self.cellContainerView.superview);
			make.top.equalTo(self.cellContainerView.superview).offset(17.f);
		}];

		NSView *launchContainerView = self.cellContainerView.containerViews.first;
		[launchContainerView addSubview:self.startAtLaunchSwitchButton];
		[self.startAtLaunchSwitchButton mas_updateConstraints:^(MASConstraintMaker *make) {
			make.left.equalTo(launchContainerView).offset(15);
			make.right.equalTo(launchContainerView).offset(-15);
			make.centerY.equalTo(launchContainerView);
			make.height.equalTo(@30);
		}];

		NSView *folderContainerView = self.cellContainerView.containerViews[1];
		[folderContainerView addSubview:self.downloadsFolderValueLabel];
		[folderContainerView addSubview:self.changeDownloadFolderButton];
		[self.downloadsFolderValueLabel mas_updateConstraints:^(MASConstraintMaker *make) {
			make.left.equalTo(folderContainerView).offset(15);
			make.right.equalTo(self.changeDownloadFolderButton.mas_left).offset(-8);
			make.centerY.equalTo(folderContainerView);
			make.height.equalTo(@25);
		}];
		[self.changeDownloadFolderButton mas_updateConstraints:^(MASConstraintMaker *make) {
			make.width.equalTo(@112);
			make.height.equalTo(@33);
			make.right.equalTo(folderContainerView).offset(-15.f);
			make.centerY.equalTo(folderContainerView);
		}];

		[self.basePreferencesView.contentView addSubview:self.versionLabel];
		[self.versionLabel setStringValue:self.versionString];
		[self.versionLabel mas_updateConstraints:^(MASConstraintMaker *make) {
			make.left.equalTo(self.versionLabel.superview).offset(10.f);
			make.bottom.equalTo(self.versionLabel.superview).offset(-10.f);
			make.height.equalTo(@20);
			make.right.equalTo(self.versionLabel.superview).offset(-10.f);
		}];

		self.downloadsFolderValueLabel.stringValue = @"/path/to/test/folder";

		[self updateFolderLabel];
		SyncScheduler *syncScheduler = [SyncScheduler sharedInstance];
		RAC(self.changeDownloadFolderButton, enabled) = [RACObserve(syncScheduler, syncing) not];

	}
	return self;
}


- (void)startAtLaunchButtonClicked:(id)startAtLaunchButtonClicked {
	NSButton *button = startAtLaunchButtonClicked;
	BOOL enabled = (BOOL) button.state;
	[SettingsManager sharedInstance].startOnLaunch = enabled;
}

- (void)changeFolderPressed:(id)changeFolderPressed {
	NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
	openPanel.canChooseFiles = NO;
	openPanel.canChooseDirectories = YES;
	openPanel.allowsMultipleSelection = NO;
	openPanel.canCreateDirectories = YES;

	[openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
		SyncScheduler *syncScheduler = [SyncScheduler sharedInstance];
		if (result == NSFileHandlingPanelOKButton && !syncScheduler.syncing) { // don't move files while syncing
			NSString *path = [openPanel.directoryURL path];

			// Help user not select a directory already containing files
			BOOL directoryIsEmpty = [self isEmptyDirectory:path];
			if (!directoryIsEmpty) {
				NSModalResponse alertResult = [self showWarningAlertForNonEmptyDirectory:path];
				if (alertResult == NSAlertFirstButtonReturn) {
					[[SettingsManager sharedInstance] setDocumentsBasePath:path];
				}
			} else {
				[[SettingsManager sharedInstance] setDocumentsBasePath:path];
			}
		}
		[self updateFolderLabel];
	}];
}

- (NSModalResponse)showWarningAlertForNonEmptyDirectory:(NSString *)path {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];
	[alert addButtonWithTitle:NSLocalizedString(@"cancel", @"Cancel")];
	[alert setMessageText:@"Use non-empty directory?"];
	NSString *infoText = [NSString stringWithFormat:NSLocalizedString(@"already-contains-files-format", nil), path];
	[alert setInformativeText:infoText];
	[alert setAlertStyle:NSWarningAlertStyle];
	NSModalResponse alertResult = [alert runModal];
	return alertResult;
}

- (BOOL)isEmptyDirectory:(NSString *)path {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *items = [fm contentsOfDirectoryAtPath:path error:nil];
	return items.count == 0;
}

- (void)updateFolderLabel {
	NSString *path = [[SettingsManager sharedInstance] documentsBasePath];
	[self.downloadsFolderValueLabel setStringValue:path];
}


- (NSButton *)startAtLaunchSwitchButton {
	if (!_startAtLaunchSwitchButton) {
		_startAtLaunchSwitchButton = [NSButton new];
		_startAtLaunchSwitchButton.title = NSLocalizedString(@"start-automatically", @"Start Postboks automatically");
		[_startAtLaunchSwitchButton setFont:[NSFont fontWithName:@"HelveticaNeue" size:14]];
		[_startAtLaunchSwitchButton setButtonType:NSSwitchButton];
		[_startAtLaunchSwitchButton setAction:@selector(startAtLaunchButtonClicked:)];
		[_startAtLaunchSwitchButton setTarget:self];
	}

	return _startAtLaunchSwitchButton;
}

- (NSTextField *)downloadsFolderValueLabel {
	if (!_downloadsFolderValueLabel) {
		_downloadsFolderValueLabel = [NSTextField new];
		[_downloadsFolderValueLabel setBezeled:NO];
		[_downloadsFolderValueLabel setDrawsBackground:NO];
		[_downloadsFolderValueLabel setEditable:NO];
		[_downloadsFolderValueLabel setSelectable:YES];
		[_downloadsFolderValueLabel setFont:[NSFont fontWithName:@"HelveticaNeue" size:14]];
		[_downloadsFolderValueLabel setTextColor:[NSColor colorWithWhite:89.f / 255.f alpha:1.f]];
		[_downloadsFolderValueLabel setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
															 forOrientation:NSLayoutConstraintOrientationHorizontal];
		[[_downloadsFolderValueLabel cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
	}
	return _downloadsFolderValueLabel;
}

- (FlatButton *)changeDownloadFolderButton {
	if (!_changeDownloadFolderButton) {
		_changeDownloadFolderButton = [FlatButton new];
		[_changeDownloadFolderButton setAllowsMixedState:YES];
		[_changeDownloadFolderButton setTitle:NSLocalizedString(@"change-folder-button", @"Change...")];
		[_changeDownloadFolderButton setTarget:self];
		[_changeDownloadFolderButton setAction:@selector(changeFolderPressed:)];
	}
	return _changeDownloadFolderButton;
}

- (NSTextField *)versionLabel {
	if (!_versionLabel) {
		_versionLabel = [NSTextField new];
		[_versionLabel setBezeled:NO];
		[_versionLabel setDrawsBackground:NO];
		[_versionLabel setEditable:NO];
		[_versionLabel setSelectable:NO];
		[_versionLabel setFont:[NSFont fontWithName:@"HelveticaNeue" size:12]];
		[_versionLabel setTextColor:[NSColor colorWithWhite:89.f / 255.f alpha:1.f]];
		[_versionLabel setAlignment:NSRightTextAlignment];
	}
	return _versionLabel;
}


#pragma mark - Helpers

- (NSString *)versionString {
	NSString *marketingVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *buildNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];

	return [NSString stringWithFormat:NSLocalizedString(@"version-format", @"Version %@ (%@)"), marketingVersion, buildNumber];
}

@end