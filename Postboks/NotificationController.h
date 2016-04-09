//
// Created by Ole Gammelgaard Poulsen on 09/04/16.
// Copyright (c) 2016 Ole Gammelgaard. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NotificationController : NSObject


- (void)handleUserClickedOnNotification:(NSUserNotification *)notification;

- (NSString *)saveNotificationUserInfo:(NSDictionary *)payload;
@end