//
//  Created by Ole Gammelgaard Poulsen on 26/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ONOXMLElement;


@interface EboksFolderInfo : NSObject

@property(nonatomic, strong) NSString *folderId;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSArray *subFolders;
@property(nonatomic, strong) NSArray *messages;

+ (instancetype)folderFromXMLElement:(ONOXMLElement *)element;

- (NSArray *)folderIdsIncludingSubfolders;
@end