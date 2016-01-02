//
//  AppDelegate.m
//  eBoksSyncHelper
//
//  Created by Ole Gammelgaard Poulsen on 23/08/14.
//  Copyright (c) 2014 Ole Gammelgaard. All rights reserved.
//

#import "HelperAppDelegate.h"

@implementation HelperAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Check if main app is already running; if yes, do nothing and terminate helper app
	BOOL alreadyRunning = NO;
	NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];

	NSString *mainAppBundleIdentifier = [self mainAppIdentifier];
	for (NSRunningApplication *app in running) {
		if ([[app bundleIdentifier] isEqualToString:mainAppBundleIdentifier]) {
			alreadyRunning = YES;
		}
	}

	if (!alreadyRunning) {
		NSString *mainAppExecutablePath = [self mainAppExecutablePath];
		[[NSWorkspace sharedWorkspace] launchApplication:mainAppExecutablePath];
	}
	[NSApp terminate:nil];
}

- (NSString *)mainAppName {
	NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ParentAppName"];
	NSAssert(name.length > 0, @"Name cannot be empty");
	return name;
}

- (NSString *)mainAppIdentifier {
	NSString *identifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ParentAppIdentifier"];
	NSAssert(identifier.length > 0, @"Identifier cannot be empty");
	return identifier;
}

- (NSString *)mainAppPath {
	NSString *helperPath = [[NSBundle mainBundle] bundlePath];
	NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[helperPath pathComponents]];
	[pathComponents removeLastObject];
	[pathComponents removeLastObject];
	[pathComponents removeLastObject];
	NSString *path = [NSString pathWithComponents:pathComponents];
	NSLog(@"main app path = %@", path);
	return path;
}

- (NSString *)mainAppExecutablePath {
	NSString *mainAppPath = [self mainAppPath];
	NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[mainAppPath pathComponents]];
	[pathComponents addObject:@"MacOS"];
	[pathComponents addObject:[self mainAppName]];
	NSString *path = [NSString pathWithComponents:pathComponents];
	NSLog(@"executable path = %@", path);
	return path;
}


@end
