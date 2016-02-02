//
// Created by Ole Gammelgaard Poulsen on 02/02/16.
// Copyright (c) 2016 Ole Gammelgaard. All rights reserved.
//

#import "SharedAccount.h"
#import "ONOXMLDocument.h"

@implementation SharedAccount {

}


+ (id)shareFromXMLElement:(ONOXMLElement *)element {
	SharedAccount *share = [SharedAccount new];
	share.userId = [element valueForAttribute:@"userId"];
	share.name = [element valueForAttribute:@"name"];

	return share;
}
@end