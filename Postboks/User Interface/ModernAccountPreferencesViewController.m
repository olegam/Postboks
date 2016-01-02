//
//  Created by Ole Gammelgaard Poulsen on 02/10/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "ModernAccountPreferencesViewController.h"
#import "BasePreferencesView.h"
#import "SidebarView.h"
#import "CellContainerView.h"
#import "EboksAccount.h"
#import <Masonry/View+MASAdditions.h>
#import <Functional.m/NSArray+F.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "CellContainerView.h"
#import "BackgroundColorView.h"
#import "FlatButton.h"
#import "SettingsManager.h"
#import "SyncScheduler.h"
#import "EboksAccount.h"
#import "ModernAddAccountWindowController.h"


@interface ModernAccountPreferencesViewController ()
@property(nonatomic, strong) BasePreferencesView *basePreferencesView;
@property(nonatomic, strong) CellContainerView *cellContainerView;
@end

@implementation ModernAccountPreferencesViewController {

}

- (instancetype)init {
	self = [super init];
	if (self) {
		self.basePreferencesView = [BasePreferencesView new];
		[self setView:self.basePreferencesView];

		[self.basePreferencesView.sidebarView setTitlesAtPositions:@{
				NSLocalizedString(@"account-sidebar-title", @"Account") : @32,
		}];

		[self rebuildView];

	}
	return self;
}

- (void)rebuildView {
	// clean up
	[self.cellContainerView removeFromSuperview];

	NSArray *accounts = [[SettingsManager sharedInstance] accounts];

	self.cellContainerView = [[CellContainerView alloc] initWithNumberOfContainers:accounts.count + 1];
	[self.basePreferencesView.contentView addSubview:self.cellContainerView];

	[self.cellContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
		make.left.bottom.right.equalTo(self.cellContainerView.superview);
		make.top.equalTo(self.cellContainerView.superview).offset(17.f);
	}];

	for (NSUInteger accountID = 0; accountID < accounts.count; accountID++) {
		EboksAccount *account = accounts[accountID];
		NSView *containerView = self.cellContainerView.containerViews[accountID];
		[self configureAccountContainer:containerView forAccount:account];
	}

	NSView *addAccountContainerView = self.cellContainerView.containerViews.lastObject;
	[self configureAddAccountContainer:addAccountContainerView];
}

- (void)configureAccountContainer:(NSView *)container forAccount:(EboksAccount *)account {
	NSImageView *accountImageView = [[NSImageView alloc] init];
	[accountImageView setImage:[NSImage imageNamed:@"account_icon"]];
	[container addSubview:accountImageView];
	[accountImageView mas_updateConstraints:^(MASConstraintMaker *make) {
		make.centerY.equalTo(container);
		make.left.equalTo(@13.f);
	}];

	NSTextField *addTextField = [NSTextField new];
	[addTextField setBezeled:NO];
	[addTextField setDrawsBackground:NO];
	[addTextField setEditable:NO];
	[addTextField setSelectable:NO];

	NSDictionary *boldAttributes = @{
			NSForegroundColorAttributeName : [NSColor colorWithWhite:89.f / 255.f alpha:1.f],
			NSFontAttributeName : [NSFont fontWithName:@"HelveticaNeue-Medium" size:15],
	};

	NSDictionary *normalAttributes = @{
			NSForegroundColorAttributeName : [NSColor colorWithWhite:89.f / 255.f alpha:1.f],
			NSFontAttributeName : [NSFont fontWithName:@"HelveticaNeue" size:15],
	};

	NSAttributedString *attributedNameString = [[NSAttributedString alloc] initWithString:account.ownerName attributes:boldAttributes];
	NSString *formattedCPR = [NSString stringWithFormat:@" (%@)", account.maskedUserId];
	NSAttributedString *attributedCPRString = [[NSAttributedString alloc] initWithString:formattedCPR attributes:normalAttributes];
	NSMutableAttributedString *attributedTitle = [NSMutableAttributedString new];
	[attributedTitle appendAttributedString:attributedNameString];
	[attributedTitle appendAttributedString:attributedCPRString];

	[addTextField setAttributedStringValue:[attributedTitle copy]];

	[container addSubview:addTextField];
	[addTextField mas_updateConstraints:^(MASConstraintMaker *make) {
		make.edges.equalTo(container).insets(NSEdgeInsetsMake(18, 50, 10, 60));
	}];

	NSButton *removeButton = [NSButton new];
	[removeButton setButtonType:NSMomentaryChangeButton];
	[removeButton setBordered:NO];
	[removeButton setTitle:@""];
	[container addSubview:removeButton];
	[removeButton mas_updateConstraints:^(MASConstraintMaker *make) {
		make.width.equalTo(@30);
		make.height.equalTo(@30);
		make.centerY.equalTo(container);
		make.right.equalTo(container).offset(-6);
	}];

	NSImageView *removeIconImageView = [[NSImageView alloc] init];
	[removeIconImageView setImage:[NSImage imageNamed:@"remove_account_icon"]];
	[removeButton addSubview:removeIconImageView];
	[removeIconImageView mas_updateConstraints:^(MASConstraintMaker *make) {
		make.center.equalTo(removeButton);
	}];

	@weakify(self)
	[removeButton setRac_command:[[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
		@strongify(self)
		[self removeAccount:account];
		return [RACSignal return:nil];
	}]];
}

- (void)configureAddAccountContainer:(NSView *)container {
	NSButton *button = [[NSButton alloc] init];
	[button setBordered:NO];
	[button setTitle:@""];
	[container addSubview:button];
	[button mas_updateConstraints:^(MASConstraintMaker *make) {
		make.edges.equalTo(container);
	}];
	[button setTarget:self];
	[button setAction:@selector(addAccountPressed:)];

	NSImageView *addAccountImageView = [[NSImageView alloc] init];
	[addAccountImageView setImage:[NSImage imageNamed:@"add_account_icon"]];
	[button addSubview:addAccountImageView];
	[addAccountImageView mas_updateConstraints:^(MASConstraintMaker *make) {
		make.centerY.equalTo(container);
		make.left.equalTo(@13.f);
	}];

	NSTextField *addTextField = [NSTextField new];
	[addTextField setBezeled:NO];
	[addTextField setDrawsBackground:NO];
	[addTextField setEditable:NO];
	[addTextField setSelectable:NO];
	[addTextField setFont:[NSFont fontWithName:@"HelveticaNeue" size:15]];
	[addTextField setTextColor:[NSColor colorWithWhite:89.f / 255.f alpha:1.f]];
	[addTextField setStringValue:NSLocalizedString(@"add-account-cell-title", @"Add account")];

	[button addSubview:addTextField];
	[addTextField mas_updateConstraints:^(MASConstraintMaker *make) {
		make.edges.equalTo(container).insets(NSEdgeInsetsMake(18, 50, 10, 30));
	}];
}

- (void)addAccountPressed:(id)sender{
	ModernAddAccountWindowController *addAccountWindowController = [[ModernAddAccountWindowController alloc] init];
	NSWindow *sheetWindow = addAccountWindowController.window;

	NSWindow *window = self.view.window;
	[window beginSheet:sheetWindow completionHandler:^(NSModalResponse returnCode) {

	}];

	@weakify(self)
	[addAccountWindowController.dismissSignal subscribeNext:^(id x) {
		@strongify(self)
		[window endSheet:addAccountWindowController.window];
		[self rebuildView];
	}];
}

- (void)removeAccount:(EboksAccount *)account {
	[[SettingsManager sharedInstance] removeAccount:account];
	[self rebuildView];
}


@end