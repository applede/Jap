//
//  SubtitleBuf.h
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>
#import <Quartz/Quartz.h>
#import "CircularQueue.h"

@class Decoder;

@interface SubtitleBuf : NSObject
{
  Decoder* _decoder;
  AVStream* _stream;
  dispatch_semaphore_t _sema;
  BOOL _quit;
  CircularQueue* _frameQue;
}

- (id)initDecoder:(Decoder*)decoder stream:(AVStream*)stream;
- (void)start;
- (void)display:(CATextLayer*)layer time:(double)t;

@end
