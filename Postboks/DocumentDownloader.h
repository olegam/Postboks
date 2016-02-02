//
//  Created by Ole Gammelgaard Poulsen on 16/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EboksSession;
@class EboksAccount;
@class RACSignal;

static NSString *const NotificationKeyPdfPaths = @"pdf_paths";
static NSString *const NotificationKeyUserName = @"user_id";
static NSString *const NotificationKeyNumFiles = @"num_files";
static NSString *const NotificationKeyNumFolders = @"num_folders";

@interface DocumentDownloader : NSObject

@property(nonatomic, readonly) EboksAccount *account;

- (instancetype)initWithAccount:(EboksAccount *)account;

+ (NSString *)baseDownloadPathForName:(NSString *)name;

- (RACSignal *)downloadNewDocumentsAndNotifyUser;

@end