//
//  Created by Ole Gammelgaard Poulsen on 02/12/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACSubject;
@class BasePreferencesView;
@class CellContainerView;


@interface ModernAddAccountWindowController : NSWindowController

@property(nonatomic, strong) RACSubject *dismissSignal;

@end