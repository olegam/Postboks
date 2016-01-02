//
//  Created by Ole Gammelgaard Poulsen on 26/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import <Ono/ONOXMLDocument.h>
#import "EboksFolderInfo.h"
#import "NSArray+F.h"

@implementation EboksFolderInfo {

}

+ (instancetype)folderFromXMLElement:(ONOXMLElement *)element {
	EboksFolderInfo *folder = [EboksFolderInfo new];
	folder.folderId = [element valueForAttribute:@"id"];
	folder.name = [element valueForAttribute:@"name"];
    
    folder.subFolders = [[element childrenWithTag:@"FolderInfo"] map:^id(ONOXMLElement *childElement) {
        return [self folderFromXMLElement:childElement];
    }];
    
	return folder;
}

- (NSArray *)folderIdsIncludingSubfolders {
	return [self.subFolders reduce:^id(NSArray *folderIds, EboksFolderInfo *subfolder) {
		return [folderIds arrayByAddingObjectsFromArray:[subfolder folderIdsIncludingSubfolders]];
	} withInitialMemo:@[self.folderId]];
}

@end