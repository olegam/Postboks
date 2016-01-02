//
//  Created by Ole Gammelgaard Poulsen on 21/09/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface TabButton : NSButton


- (id)initWithTitle:(NSString *)title icon:(NSImage *)icon;

@property(nonatomic, assign) BOOL selectedTab;

@end