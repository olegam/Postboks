//
//  Created by Ole Gammelgaard Poulsen on 02/12/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Masonry/Masonry.h>
#import "ModernAddAccountWindowController.h"
#import "RACSubject.h"
#import "SettingsManager.h"
#import "EboksSession.h"
#import "APIClient.h"
#import "EboksAccount.h"
#import "CellContainerView.h"
#import "BasePreferencesView.h"
#import "SidebarView.h"
#import "BackgroundColorView.h"
#import "CenteredTextField.h"
#import "RACSignal+Operations.h"

@interface ModernAddAccountWindowController ()
@property(nonatomic, strong) BasePreferencesView *basePreferencesView;
@property(nonatomic, strong) CellContainerView *cellContainerView;

@property(nonatomic, strong) NSButton *cancelButton;
@property(nonatomic, strong) NSButton *saveButton;

@property(nonatomic, strong) CenteredTextField *userIdTextField;
@property(nonatomic, strong) CenteredTextField *passwordTextField;
@property(nonatomic, strong) CenteredTextField *activationCodeTextField;
@property(nonatomic, strong) NSPopUpButton *nationalityPopupButton;
@end

@implementation ModernAddAccountWindowController {

}

- (instancetype)init {
	NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 540, 340)
												   styleMask:NSTitledWindowMask | NSClosableWindowMask
													 backing:NSBackingStoreBuffered defer:NO];
	self = [super initWithWindow:window];
	if (self) {
		[self addSubviews];
		[self defineLayout];
		self.dismissSignal = [RACSubject subject];
	}
	return self;
}

- (void)addSubviews {
	self.basePreferencesView = [BasePreferencesView new];
	[self.window setContentView:self.basePreferencesView];

	[self.basePreferencesView.sidebarView setTitlesAtPositions:@{
			NSLocalizedString(@"cpr-legend", @"Social security #:") : @34,
			NSLocalizedString(@"password-legend", @"Password:") : @91,
			NSLocalizedString(@"activation-code-legend", @"Activation code:") : @148,
			NSLocalizedString(@"country-legend", @"Country:") : @208,
	}];

	self.cellContainerView = [[CellContainerView alloc] initWithNumberOfContainers:4];
	[self.basePreferencesView.contentView addSubview:self.cellContainerView];

	BackgroundColorView *cprContainer = self.cellContainerView.containerViews[0];
	BackgroundColorView *passwordContainer = self.cellContainerView.containerViews[1];
	BackgroundColorView *activationCodeContainer = self.cellContainerView.containerViews[2];
  BackgroundColorView *nationalityContainer = self.cellContainerView.containerViews[3];
  
  nationalityContainer.backgroundColor = [NSColor clearColor];
  
	[self installTextField:self.userIdTextField inContainer:cprContainer];
	[self installTextField:self.passwordTextField inContainer:passwordContainer];
	[self installTextField:self.activationCodeTextField inContainer:activationCodeContainer];
  [self installTextField:self.nationalityPopupButton inContainer:nationalityContainer];

	[self.basePreferencesView addSubview:self.cancelButton];
	[self.basePreferencesView addSubview:self.saveButton];

}

- (void)defineLayout {
	[self.cellContainerView mas_updateConstraints:^(MASConstraintMaker *make) {
		make.left.bottom.right.equalTo(self.cellContainerView.superview);
		make.top.equalTo(self.cellContainerView.superview).offset(17.f);
	}];

	NSView *lastFieldContainer = self.cellContainerView.containerViews.lastObject;
	[self.cancelButton mas_updateConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(lastFieldContainer.mas_bottom).offset(24.f);
		make.left.equalTo(lastFieldContainer);
		make.height.equalTo(@43);
		make.width.equalTo(lastFieldContainer).multipliedBy(0.5f).offset(-4.f);
	}];

	[self.saveButton mas_updateConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(self.cancelButton);
		make.right.equalTo(lastFieldContainer);
		make.height.equalTo(self.cancelButton);
		make.width.equalTo(self.cancelButton);
	}];
}

- (void)installTextField:(NSView *)textField inContainer:(NSView *)container {
	[container addSubview:textField];
	[textField mas_updateConstraints:^(MASConstraintMaker *make) {
		make.edges.equalTo(container).insets(NSEdgeInsetsMake(0, 2, 0, 2));
	}];
}

- (void)cancelPressed:(id)cancelPressed {
	[self.dismissSignal sendNext:nil];
}

-(void)saveTapped:(id)sender {
	[self.userIdTextField endEditing];
	[self.passwordTextField endEditing];
	[self.activationCodeTextField endEditing];

	EboksAccount *account = [EboksAccount new];
	account.userId = self.userIdTextField.string;
	account.password = self.passwordTextField.string;
	account.activationCode = self.activationCodeTextField.string;
  account.nationality = [self selectedNationality];

	NSString *errorMessage = nil;
	if (account.password.length == 0) {
		errorMessage = @"You must enter the password you have chosen to use for mobile access on e-boks.dk";
	}
	if (account.activationCode.length == 0) {
		errorMessage = @"You must enter the activation code that you can find on e-boks if you go to the mobile access section";
	}

	if ([[SettingsManager sharedInstance] hasAccountForId:account.userId]) {
		errorMessage = [NSString stringWithFormat:NSLocalizedString(@"account-already-exists", @"There is already an account with id %@"), account.userId];
	}

	if (errorMessage) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:errorMessage];
		[alert runModal];
		return;
	}

	[[[APIClient sharedInstanceForAccount:account] getSessionForAccount:account] subscribeNext:^(EboksSession *session) {
		[[SettingsManager sharedInstance] saveAccount:account];
		[self.dismissSignal sendNext:nil];
	} error:^(NSError *error) {
		NSString *errorMessage = [error localizedDescription];
		if (error.code == -1011) {
			errorMessage = NSLocalizedString(@"invalid-login-credentials", @"The credentials you entered could not be verified.");
		}

		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:errorMessage];
		[alert runModal];
	}];
}

- (NSButton *)cancelButton {
	if (!_cancelButton) {
		_cancelButton = [NSButton new];
		[_cancelButton setTitle:NSLocalizedString(@"cancel", @"Cancel")];
		[_cancelButton setBezelStyle:NSSmallSquareBezelStyle];
		[_cancelButton setAction:@selector(cancelPressed:)];
		[_cancelButton setTarget:self];
	}
	return _cancelButton;
}

- (NSButton *)saveButton {
	if (!_saveButton) {
		_saveButton = [NSButton new];
		[_saveButton setTitle:NSLocalizedString(@"save", @"Save")];
		[_saveButton setBezelStyle:NSSmallSquareBezelStyle];
		[_saveButton setAction:@selector(saveTapped:)];
		[_saveButton setTarget:self];
	}
	return _saveButton;
}

- (CenteredTextField *)userIdTextField {
	if(!_userIdTextField) {
		_userIdTextField = [CenteredTextField new];
		_userIdTextField.drawsBorder = NO;
		_userIdTextField.placeholderString = @"";
	}
	return _userIdTextField;
}

- (CenteredTextField *)passwordTextField {
	if(!_passwordTextField) {
		_passwordTextField = [CenteredTextField new];
		_passwordTextField.drawsBorder = NO;
		_passwordTextField.placeholderString = @"";
		_passwordTextField.secure = YES;
	}
	return _passwordTextField;
}

- (CenteredTextField *)activationCodeTextField {
	if(!_activationCodeTextField) {
		_activationCodeTextField = [CenteredTextField new];
		_activationCodeTextField.drawsBorder = NO;
		_activationCodeTextField.placeholderString = @"";
		_activationCodeTextField.secure = YES;
		_activationCodeTextField.continuous = YES;
	}
	return _activationCodeTextField;
}

- (NSPopUpButton *)nationalityPopupButton {
  if(!_nationalityPopupButton) {
    _nationalityPopupButton = [NSPopUpButton new];
    [_nationalityPopupButton addItemsWithTitles:@[
      NSLocalizedString(@"country-denmark", @"Denmark"),
      NSLocalizedString(@"country-sweden", @"Sweden")
    ]];
  }
  
  return _nationalityPopupButton;
}

- (NSString *)selectedNationality {
  return self.nationalityPopupButton.indexOfSelectedItem == 1
    ? EboksNationalitySweden : EboksNationalityDenmark;
}

@end