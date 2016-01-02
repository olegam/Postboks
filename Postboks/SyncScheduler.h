//
//  Created by Ole Gammelgaard Poulsen on 17/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SyncScheduler : NSObject

@property(nonatomic, assign) BOOL syncing;
@property(nonatomic, assign) BOOL failed;

@property(nonatomic, copy) NSString *nextSyncDescription;

+ (SyncScheduler *)sharedInstance;


- (void)startSync:(BOOL)userInitiated;
@end