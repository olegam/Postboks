//
//  Created by Ole Gammelgaard Poulsen on 17/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "SettingsManager.h"
#import "EboksAccount.h"
#import "SSKeychain.h"
#import "NSArray+F.h"
#import "AppDelegate.h"
#import <ServiceManagement/ServiceManagement.h>
#import <AppKit/AppKit.h>
#import <MacTypes.h>

static NSString *const HelperAppBundleId = @"dk.postboks.helper";
static NSString *const SettingsKeyStartOnLaunch = @"start_on_launch";
static NSString *const SettingsKeyLastCompletedSyncDate = @"last_completed_sync_date";
static NSString *const SettingsKeyDownloadInterval = @"download_interval";

@implementation SettingsManager {
	NSUserDefaults *_defaults;
	NSArray *_cachedAccounts;
}

+ (SettingsManager *)sharedInstance {
	static SettingsManager *sharedInstance = nil;
	if (sharedInstance) return sharedInstance;
	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
		sharedInstance = [[SettingsManager alloc] init];
	});
	return sharedInstance;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_defaults = [NSUserDefaults standardUserDefaults];

		[_defaults registerDefaults:@{
			SettingsKeyDownloadInterval : @(3600.0),
		}];
		[_defaults synchronize];
	}
	return self;
}


- (NSString *)keychainServiceName {
	AppDelegate *delegate = [[NSApplication sharedApplication] delegate];
	NSString *name = delegate.appBundleIdentifier;
	NSAssert(name.length > 0, @"Name must not be empty");
	return name;
}


- (NSString *)documentsBasePath {
	NSData *bookmarkData = [_defaults valueForKey:PostboksDocumentBaseBookmarkKey];
	if (bookmarkData) {
		BOOL stale = NO;
		NSError *error = nil;
		NSURL *url = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithSecurityScope
										 relativeToURL:nil bookmarkDataIsStale:&stale error:&error];
		if (stale) {
			NSLog(@"Bookmark is stale");
			NSError *saveError = nil;
			NSData *updatedBookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:@[]
														 relativeToURL:nil error:&saveError];
			[_defaults setValue:updatedBookmarkData forKey:PostboksDocumentBaseBookmarkKey];
			[_defaults synchronize];
		}
		if (error) {
			NSLog(@"Error restoring security-scoped bookmark %@", error);
			[self setDocumentsBasePath:nil andMoveFiles:false];
		}
		NSString *path = [url path];
		if ([self validDirectoryAtPath:path]) {
			[url startAccessingSecurityScopedResource];
			return path;
		}
	}
	return [self defaultBasePath];
}

- (BOOL)validDirectoryAtPath:(NSString *)path {
	BOOL isDirectory = NO;
	[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
	return isDirectory;
}

- (NSString *)defaultBasePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = paths.firstObject;
	NSString *pdfBaseFolder = [documentsDirectory stringByAppendingPathComponent:@"eboks downloads"];
	return pdfBaseFolder;
}

- (void)setDocumentsBasePath:(NSString *)documentsBasePath andMoveFiles:(bool)move {
	if (!documentsBasePath) {
		[_defaults removeObjectForKey:PostboksDocumentBaseBookmarkKey];
		[_defaults synchronize];
		return;
	}
	NSString *oldPath = [self documentsBasePath];

	NSURL *url = [NSURL fileURLWithPath:documentsBasePath];
	NSError *error = nil;
	NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:@[]
				   relativeToURL:nil error:&error];
	if (error) {
		NSLog(@"Error creating security-scoped bookmark for %@ : %@", documentsBasePath, error);
		return;
	}

	[_defaults setValue:bookmarkData forKey:PostboksDocumentBaseBookmarkKey];
	[_defaults synchronize];

	if (move) {
		// move the files
		NSFileManager *fm = [NSFileManager defaultManager];
		NSArray *items = [fm contentsOfDirectoryAtPath:oldPath error:nil];
		for (NSString *itemPath in items) {
			NSString *sourcePath = [oldPath stringByAppendingPathComponent:itemPath];
			NSString *destinationPath = [documentsBasePath stringByAppendingPathComponent:itemPath];
			if ([self validDirectoryAtPath:sourcePath]) {
				NSError *moveError = nil;
				BOOL moved = [fm moveItemAtPath:sourcePath toPath:destinationPath error:&moveError];
				if (!moved && moveError) {
					NSLog(@"Error moving directory: %@ from %@ to %@", [moveError localizedDescription], sourcePath, destinationPath);
				}
			}
		}
	}
}

- (NSArray *)accounts {
	if (_cachedAccounts) return _cachedAccounts;
	NSArray *keychainAccountUserIds = [[SSKeychain accountsForService:[self keychainServiceName]] map:^id(NSDictionary *dict) {
		return dict[kSSKeychainAccountKey];
	}];
	NSArray *eboksAccounts = [keychainAccountUserIds map:^id(NSString *userId) {
		SSKeychainQuery *fetchUserQuery = [[SSKeychainQuery alloc] init];
		fetchUserQuery.service = [self keychainServiceName];
		fetchUserQuery.account = userId;
		fetchUserQuery.synchronizationMode = SSKeychainQuerySynchronizationModeAny;

		NSError *error = nil;
		[fetchUserQuery fetch:&error];
		EboksAccount *account = (EboksAccount *) fetchUserQuery.passwordObject;
		if (error && error.code != errSecItemNotFound) {
			NSLog(@"Could not fetch user from keychain %@", error);
		}
		return account;
	}];

	_cachedAccounts = eboksAccounts ?: @[];
	return _cachedAccounts;
}

- (void)saveAccount:(EboksAccount *)account {
	_cachedAccounts = nil;
	[self willChangeValueForKey:@"accounts"];
	NSAssert(![self hasAccountForId:account.userId], @"Already has account with id %@", account.userId);
	BOOL validAccount = account.userId && account.password && account.activationCode;
	NSAssert(validAccount, @"User must have a name and token");
	if (!validAccount) return; // never store crap in keychain
	SSKeychainQuery *saveUserQuery = [[SSKeychainQuery alloc] init];
	saveUserQuery.service = [self keychainServiceName];
	saveUserQuery.account = account.userId;
	saveUserQuery.passwordObject = (id<NSCoding>) account;
	NSError *error = nil;
	[saveUserQuery save:&error];
	if (error) {
		NSLog(@"Could not save user to keychain %@", error);
	}
	[self didChangeValueForKey:@"accounts"];
}

- (BOOL)hasAccountForId:(NSString *)accountId {
	return [[self accounts] isValidForAny:^BOOL(EboksAccount *a) {
		return [a.userId isEqualToString:accountId];
	}];
}

- (void)removeAccount:(EboksAccount *)account {
	_cachedAccounts = nil;
	[self willChangeValueForKey:@"accounts"];
	SSKeychainQuery *removeQuery = [[SSKeychainQuery alloc] init];
	removeQuery.service = [self keychainServiceName];
	removeQuery.account = account.userId;
	NSError *error = nil;
	[removeQuery deleteItem:&error];
	if (error) {
		NSLog(@"Could not remove user from keychain %@", error);
	}
	[self didChangeValueForKey:@"accounts"];
}

- (NSTimeInterval)downloadInterval {
	return [_defaults doubleForKey:SettingsKeyDownloadInterval];
}

- (void)setDownloadInterval:(NSTimeInterval)downloadInterval {
	[_defaults setDouble:downloadInterval forKey:SettingsKeyDownloadInterval];
	[_defaults synchronize];
}

- (NSDate *)lastCompletedSyncDate {
	return [_defaults valueForKey:SettingsKeyLastCompletedSyncDate];
}

- (void)setLastCompletedSyncDate:(NSDate *)lastCompletedSyncDate {
	[_defaults setValue:lastCompletedSyncDate forKey:SettingsKeyLastCompletedSyncDate];
	[_defaults synchronize];
}

#pragma mark - Auto start

- (BOOL)startOnLaunch {
	return [_defaults boolForKey:SettingsKeyStartOnLaunch];
}

- (void)setStartOnLaunch:(BOOL)startOnLaunch {
	[_defaults setBool:startOnLaunch forKey:SettingsKeyStartOnLaunch];
	[_defaults synchronize];


	if (startOnLaunch) { // ON
		// Turn on launch at login
		if (!SMLoginItemSetEnabled ((__bridge CFStringRef) HelperAppBundleId, YES)) {
			NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"error-title", @"An error ocurred")
											 defaultButton:NSLocalizedString(@"OK", @"OK")
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"automatic-launch-activate-error", @"Could not activate automatic launch.")];
			[alert runModal];
		}
	} else {
		// Turn off launch at login
		if (!SMLoginItemSetEnabled ((__bridge CFStringRef) HelperAppBundleId, NO)) {
			NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"error-title", @"An error ocurred")
											 defaultButton:NSLocalizedString(@"OK", @"OK")
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat:NSLocalizedString(@"automatic-launch-deactivate-launch", @"Could not deactivate automatic launch.")];
			[alert runModal];
		}
	}
}



@end