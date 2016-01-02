//
//  Created by Ole Gammelgaard Poulsen on 20/09/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TabBarView : NSView

@property(nonatomic, assign) NSInteger selectedIndex;

- (instancetype)initWithButtons:(NSArray *)buttons;

@end