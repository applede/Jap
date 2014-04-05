//
//  Section.m
//  Jap
//
//  Created by Jake Song on 4/5/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "Section.h"

static dispatch_queue_t _backgroundScan;

@implementation Section

- (id)initName:(NSString *)name folders:(NSArray *)folders
{
  self = [super self];
  if (self) {
    _name = name;
    _folders = folders;
    if (!_backgroundScan) {
      _backgroundScan = dispatch_queue_create("jap.background.scan", DISPATCH_QUEUE_SERIAL);
    }
  }
  return self;
}

- (NSString*)randomFanart
{
  if (_fanarts) {
    return [_fanarts objectAtIndex:arc4random_uniform((u_int32_t)[_fanarts count])];
  } else {
    _fanarts = [[NSMutableArray alloc] init];
    dispatch_async(_backgroundScan, ^{
      [_folders enumerateObjectsUsingBlock:^(NSString* folder, NSUInteger idx, BOOL *stop) {
        NSEnumerator* e = [[NSFileManager defaultManager] enumeratorAtPath:folder];
        NSString* path;
        while (path = [e nextObject]) {
          if ([[path lastPathComponent] isEqualToString:@"fanart.jpg"]) {
            NSString* fullPath = [folder stringByAppendingPathComponent:path];
            [_fanarts addObject:fullPath];
          }
        }
      }];
    });
    return nil;
  }
}

@end
