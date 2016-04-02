//
// Created by Ole Gammelgaard Poulsen on 02/04/16.
// Copyright (c) 2016 Ole Gammelgaard. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MigrationManager : NSObject
+ (MigrationManager *)sharedInstance;


- (void)performMigrations;
@end