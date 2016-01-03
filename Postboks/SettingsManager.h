//
//  Created by Ole Gammelgaard Poulsen on 17/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EboksAccount;


static NSString *const PostboksDocumentBaseBookmarkKey = @"documentBaseBookmark";

@interface SettingsManager : NSObject

@property(nonatomic, readonly) NSArray *accounts;
@property(nonatomic, assign) NSTimeInterval downloadInterval;
@property(nonatomic, strong) NSDate *lastCompletedSyncDate;
@property(nonatomic, assign) BOOL startOnLaunch;

+ (SettingsManager *)sharedInstance;


- (void)saveAccount:(EboksAccount *)account;

- (BOOL)hasAccountForId:(NSString *)accountId;

- (void)removeAccount:(EboksAccount *)account;

- (NSString *)documentsBasePath;

- (void)setDocumentsBasePath:(NSString*)path andMoveFiles:(bool)move;

@end