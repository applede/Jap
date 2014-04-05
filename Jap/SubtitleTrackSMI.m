//
//  SubtitleTrackSMI.m
//  Jap
//
//  Created by Jake Song on 3/31/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "SubtitleTrackSMI.h"
#import "ParserSMI.h"

@implementation SubtitleTrackSMI

- (id)initDecoder:(Decoder *)decoder stream:(AVStream*)stream path:(NSString *)path
{
  self = [super initDecoder:decoder stream:stream];
  if (self) {
    ParserSMI* parser = [[ParserSMI alloc] initPath:path];
    if (parser) {
      _nodes = [parser nodes];
      _current = 0;
      return self;
    }
  }
  return nil;
}

- (NSString*)stringForTime:(double)t
{
  NSString* ret = nil;
  int i = _current;
  while (YES) {
    Node* node = [_nodes objectAtIndex:i];
    double time = av_q2d(_stream->time_base) * [node time];
    if (time <= t) {
      ret = [node string];
      i++;
    } else {
      break;
    }
  }
  _current = i;
  return ret;
}

@end
