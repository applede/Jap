//
//  Decoder.m
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <libavcodec/avcodec.h>
#import "Decoder.h"

@implementation Decoder

- (id)init
{
  self = [super init];
  if (self) {
    _videoQ = [[VideoQueue alloc] init];
  }
  return self;
}

- (void)start
{
  _sema = dispatch_semaphore_create(0);
  dispatch_queue_t decodeQ = dispatch_queue_create("jap.decode", DISPATCH_QUEUE_SERIAL);
  dispatch_async(decodeQ, ^{
    while (!_quit) {
      while (!_quit && ![_videoQ isFull]) {
        [self decode];
      }
      
      dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
    }
  });
}

- (void)decode
{
#if 1
  [_videoQ generateDebugData];
#else
  int got_picture = NO;
  AVPacket *pkt;
  if (avcodec_decode_video2(_video_st->codec, _frame, &got_picture, pkt) < 0) {
    NSLog(@"avcodec_decode_video2");
    return;
  }
#endif
}

- (void)remove
{
  [_videoQ remove];
  dispatch_semaphore_signal(_sema);
}

@end
