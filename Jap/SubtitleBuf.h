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

@class Decoder;

@interface SubtitleBuf : NSObject
{
  Decoder* _decoder;
  AVStream* _stream;
  dispatch_queue_t _q;
  dispatch_semaphore_t _sema;
  BOOL _quit;
  
  NSLock* _lock;
  int _size;
  int _count;
  int _front;
  int _back;
  double *_time;
  AVSubtitle *_sub;
}

@property (weak) CATextLayer* layer;

- (void)setDecoder:(Decoder*)decoder stream:(AVStream *)stream;
- (void)start;
- (void)display:(CATextLayer*)layer time:(double)t;

@end
