//
//  SubtitleBuf.m
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "SubtitleTrack.h"
#import "SubtitleFrame.h"

@implementation SubtitleTrack

- (id)initDecoder:(Decoder *)decoder stream:(AVStream *)stream
{
  self = [super init];
  if (self) {
    _decoder = decoder;
    _stream = stream;
    _sema = dispatch_semaphore_create(0);
  }
  return self;
}

- (void)start
{
}

- (NSString*)stringForTime:(double)t
{
  return nil;
}

@end
