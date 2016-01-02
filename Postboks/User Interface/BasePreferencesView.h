//
//  Created by Ole Gammelgaard Poulsen on 02/10/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class SidebarView;
@class BackgroundColorView;


@interface BasePreferencesView : NSView

@property(nonatomic, strong) SidebarView *sidebarView;
@property(nonatomic, strong) BackgroundColorView *contentView;

@end