//
//  Created by Ole Gammelgaard Poulsen on 17/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "SyncScheduler.h"
#import "SettingsManager.h"
#import "EboksAccount.h"
#import "DocumentDownloader.h"
#import "TTTTimeIntervalFormatter.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>


@implementation SyncScheduler {

}
+ (SyncScheduler *)sharedInstance {
	static SyncScheduler *sharedInstance = nil;
	if (sharedInstance) return sharedInstance;
	static dispatch_once_t pred;
	dispatch_once(&pred, ^{
		sharedInstance = [[SyncScheduler alloc] init];
	});
	return sharedInstance;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		self.nextSyncDescription = @"";

		[self startSync:NO];

		AFNetworkReachabilityManager *reachabilityManger = [AFNetworkReachabilityManager sharedManager];
		[reachabilityManger startMonitoring];
		RACSignal *reachableSignal = RACObserve(reachabilityManger, reachable);

		RACSignal *pulseSignal = [[RACSignal interval:2.f onScheduler:[RACScheduler mainThreadScheduler] withLeeway:1.f] startWith:nil];

		RACSignal *shouldSyncTimerSignal = [[[pulseSignal combineLatestWith:reachableSignal] filter:^BOOL(RACTuple *tuple) {
			// figure out if we need to sync now
			BOOL reachable = [tuple.second boolValue];
			if (!reachable) return NO;
			SettingsManager *settingsManager = [SettingsManager sharedInstance];
			NSTimeInterval syncInterval = [settingsManager downloadInterval];
			NSDate *lastCompletedSyncDate = [settingsManager lastCompletedSyncDate];
			if (!lastCompletedSyncDate) return YES;
			NSTimeInterval intervalSinceSync = -[lastCompletedSyncDate timeIntervalSinceNow];
			return intervalSinceSync > syncInterval;
		}] mapReplace:@(NO)];

		__weak SyncScheduler *weakSelf = self;
		RAC(self, nextSyncDescription) = [[RACSignal combineLatest:@[pulseSignal, RACObserve(self, syncing), reachableSignal]] map:^id(RACTuple *tuple) {
			BOOL reachable = [tuple.third boolValue];
			if (!reachable) return NSLocalizedString(@"no-internet", @"No Internet");
			SettingsManager *settingsManager = [SettingsManager sharedInstance];
			if (settingsManager.accounts.count == 0) return NSLocalizedString(@"no-accounts", @"No accounts");
			NSTimeInterval syncInterval = [settingsManager downloadInterval] + 60.f;
			BOOL syncing = [tuple.second boolValue];
			if (syncing) {
				TTTTimeIntervalFormatter *syncAgaintimeIntervalFormatter = [[TTTTimeIntervalFormatter alloc] init];
				syncAgaintimeIntervalFormatter.presentDeicticExpression = @"";
				syncAgaintimeIntervalFormatter.futureDeicticExpression = @"";
				NSString *intervalString = [syncAgaintimeIntervalFormatter stringForTimeInterval:syncInterval];
				return [NSString stringWithFormat:NSLocalizedString(@"syncs-every", @"Syncs every %@"), intervalString];
			}

			NSDate *lastCompletedSyncDate = [settingsManager lastCompletedSyncDate];
			NSDate *nextSync = [lastCompletedSyncDate dateByAddingTimeInterval:syncInterval];
			NSTimeInterval interValUntilSync = [nextSync timeIntervalSinceNow];

			TTTTimeIntervalFormatter *syncAgaintimeIntervalFormatter = [[TTTTimeIntervalFormatter alloc] init];
			syncAgaintimeIntervalFormatter.presentDeicticExpression = @"";
			syncAgaintimeIntervalFormatter.futureDeicticExpression = @"";
			NSString *syncAgainIntervalString = [syncAgaintimeIntervalFormatter stringForTimeInterval:interValUntilSync];
			NSString *intervalFormat =  NSLocalizedString(@"next-sync-in", @"Next sync in %@");
			if (weakSelf.failed) {
				intervalFormat = NSLocalizedString(@"failed-retry-in", @"Failed. Retry in %@");
			}

			return [NSString stringWithFormat:intervalFormat, syncAgainIntervalString];
		}];

		[self rac_liftSelector:@selector(startSync:) withSignalsFromArray:@[shouldSyncTimerSignal]];
	}
	return self;
}

- (void)startSync:(BOOL)userInitiated {
	if (self.syncing) return;
	self.syncing = YES;
	__weak SyncScheduler *weakSelf = self;
	NSArray *accounts = [[SettingsManager sharedInstance] accounts];
	[[[[accounts rac_sequence] signal] flattenMap:^RACStream *(EboksAccount *account) {
		DocumentDownloader *downloader = [[DocumentDownloader alloc] initWithAccount:account];
		return [downloader downloadNewDocumentsAndNotifyUser];
	}] subscribeError:^(NSError *error) {
		weakSelf.syncing = NO;
		weakSelf.failed = YES;
	} completed:^{
		weakSelf.syncing = NO;
		weakSelf.failed = NO;
		[[SettingsManager sharedInstance] setLastCompletedSyncDate:[NSDate date]];
	}];
}


@end
