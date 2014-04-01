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
  self = [super init];
  if (self) {
    ParserSMI* parser = [[ParserSMI alloc] initPath:path];
    if (parser) {
      _nodes = [parser nodes];
      _current = 0;
      _stream = stream;
      return self;
    }
  }
  return nil;
}

- (void)display:(CATextLayer*)layer time:(double)t
{
  Node* node = [_nodes objectAtIndex:_current];
  double time = av_q2d(_stream->time_base) * [node time];
  if (time <= t) {
    NSAttributedString* str =
    [[NSAttributedString alloc] initWithString:[node string]
                                    attributes:@{ NSFontAttributeName:[NSFont fontWithName:@"Helvetica Neue" size:24.0], NSForegroundColorAttributeName:[NSColor whiteColor],
                                          NSStrokeWidthAttributeName:@(-1.0),
                                          NSStrokeColorAttributeName:[NSColor blackColor]}];
    
    layer.string = str;
    _current++;
  }
}

@end
