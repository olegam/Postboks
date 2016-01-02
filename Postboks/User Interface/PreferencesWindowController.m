//
//  Created by Ole Gammelgaard Poulsen on 20/09/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "StyledWindow.h"
#import "TabBarView.h"
#import "View+MASAdditions.h"
#import "TabButton.h"
#import "SidebarView.h"
#import "ModernGeneralPreferencesViewController.h"
#import "ModernAccountPreferencesViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface PreferencesWindowController ()
@property(nonatomic, strong) TabBarView *tabBarView;

@property(nonatomic, strong) NSArray *viewControllers;
@property(nonatomic, strong) NSViewController *selectedViewController;

@end

@implementation PreferencesWindowController {

}


- (instancetype)init {
	StyledWindow *window = [[StyledWindow alloc] initWithContentRect:NSMakeRect(0, 0, 600, 400)];
	[window setMinSize:CGSizeMake(600, 400)];
	window.title = NSLocalizedString(@"preferences-title", @"Preferences");

	self = [super initWithWindow:window];
	if (self) {
		TabButton *generalButton = [[TabButton alloc] initWithTitle:@"General" icon:[NSImage imageNamed:@"general_icon"]];
		TabButton *accountsButton = [[TabButton alloc] initWithTitle:@"Accounts" icon:[NSImage imageNamed:@"accounts_icon"]];
		self.tabBarView = [[TabBarView alloc] initWithButtons:@[generalButton, accountsButton]];

		NSView *contentView = window.contentView;
		[contentView addSubview:self.tabBarView];

		[self.tabBarView mas_updateConstraints:^(MASConstraintMaker *make) {
			make.left.top.right.equalTo(contentView);
			make.height.equalTo(@70);
		}];

		self.viewControllers = @[[ModernGeneralPreferencesViewController new], [ModernAccountPreferencesViewController new]];
		[self rac_liftSelector:@selector(setSelectedViewControllerIndex:) withSignals:RACObserve(self.tabBarView, selectedIndex), nil];

	}
	return self;
}

- (void)setSelectedViewControllerIndex:(NSUInteger)selectedViewControllerIndex {
	self.selectedViewController = self.viewControllers[selectedViewControllerIndex];
}

- (void)setSelectedViewController:(NSViewController *)selectedViewController {

	if (_selectedViewController) {
		[_selectedViewController.view removeFromSuperview];
	}

	[self.window.contentView addSubview:selectedViewController.view];

	[selectedViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.tabBarView.mas_bottom);
		make.left.bottom.right.equalTo(selectedViewController.view.superview);
	}];


	_selectedViewController = selectedViewController;

}


@end