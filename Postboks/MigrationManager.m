//
// Created by Ole Gammelgaard Poulsen on 02/04/16.
// Copyright (c) 2016 Ole Gammelgaard. All rights reserved.
//

#import "MigrationManager.h"
#import "SettingsManager.h"
#import "NSArray+F.h"
#import "DocumentDownloader.h"

static NSString *const CurrentMigratedVersionKey = @"current_migrated_version";

@implementation MigrationManager {

}

+ (MigrationManager *)sharedInstance {
	static MigrationManager *sharedInstance = nil;
	if (sharedInstance) return sharedInstance;
	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
		sharedInstance = [[MigrationManager alloc] init];
	});
	return sharedInstance;
}

- (NSInteger)currentMigrationVersion {
	return [[NSUserDefaults standardUserDefaults] integerForKey:CurrentMigratedVersionKey];
}

- (void)setMigratedVersion:(NSInteger)version {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:version forKey:CurrentMigratedVersionKey];
	[defaults synchronize];
}

- (void)performMigrations {
//	NSInteger previousVersion = [self currentMigrationVersion];
	if ([self currentMigrationVersion] <= 28) {
		[self migrateForDelegatedAccountsSupport];
		[self setMigratedVersion:29];
	}

	// after performing all required migrations save current build number as last migrated to version
	NSString *buildVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *) kCFBundleVersionKey];
	NSInteger currentVersion = [buildVersion integerValue];
	NSAssert(currentVersion > 0, @"Version must be integer larger than 0: %@", buildVersion);
	[self setMigratedVersion:currentVersion];
}

- (void)migrateForDelegatedAccountsSupport {
	NSArray *accounts = [[SettingsManager sharedInstance] accounts];
	[[accounts map:^id(EboksAccount *account) {
		return [[DocumentDownloader alloc] initWithAccount:account];
	}] enumerateObjectsUsingBlock:^(DocumentDownloader *documentDownloader, NSUInteger idx, BOOL *stop) {
		[documentDownloader trashLegacyFolder];
	}];
}

@end