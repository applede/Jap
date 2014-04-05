//
//  AppDelegate.m
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "AppDelegate.h"
#import "Section.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  // Insert code here to initialize your application
//  [_window toggleFullScreen:self];
  [_window setDelegate:_view];
  NSArray* sections = @[[[Section alloc] initName:@"영화" folders:@[@"/Users/apple/hobby/test_jamp/movie"]],
                        [[Section alloc] initName:@"TV" folders:@[]],
                        [[Section alloc] initName:@"음악" folders:@[]],
                        [[Section alloc] initName:@"설정" folders:@[]] ];
  [_view setSections:sections];
//  [_view open:@"/Users/apple/hobby/test_jamp/movie/5 Centimeters Per Second (2007)/5 Centimeters Per Second.mkv"];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
  return YES;
}

@end
