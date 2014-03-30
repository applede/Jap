//
//  SubtitleBuf.m
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "SubtitleBuf.h"
#import "Decoder.h"
#import "Packet.h"
#import "SubtitleFrame.h"

#define QSIZE 32

@implementation SubtitleBuf

- (id)initDecoder:(Decoder *)decoder stream:(AVStream *)stream
{
  self = [super init];
  if (self) {
    _decoder = decoder;
    _stream = stream;
    _sema = dispatch_semaphore_create(0);
    _frameQue = [[CircularQueue alloc] initSize:QSIZE];
    for (int i = 0; i < QSIZE; i++) {
      _frameQue[i] = [[SubtitleFrame alloc] init];
    }
  }
  return self;
}

- (void)start
{
  dispatch_queue_t q = dispatch_queue_create("jap.subtitle", DISPATCH_QUEUE_SERIAL);
  dispatch_async(q, ^{
    int got_subtitle;
    double pts;
    
    while (!_quit) {
      @autoreleasepool {
        while (!_quit && ![_decoder.subtitleQue isEmpty] && ![_frameQue isFull]) {
          Packet* packet = [_decoder.subtitleQue get];
          pts = 0;
          if (packet.pts != AV_NOPTS_VALUE)
            pts = av_q2d(_stream->time_base) * packet.pts;
          SubtitleFrame* s = [_frameQue back];
          avcodec_decode_subtitle2(_stream->codec, s.sub, &got_subtitle, packet.packet);
          if (got_subtitle) {
            if (s.pts != AV_NOPTS_VALUE)
                pts = s.pts / (double)AV_TIME_BASE;
            if (s.rects) {
              [self put:s time:pts];
            } else {
              assert(s.rects);
            }
          }
        }
        dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
      }
    }
  });
}

- (void)put:(SubtitleFrame*)s time:(double)time
{
  s.time = time;
  [_frameQue advance];
}

- (SubtitleFrame*)get:(double)time
{
  SubtitleFrame* s = [_frameQue front];
  if (s.time <= time) {
    return s;
  }
  return nil;
}

static const char* findSub(const char* str)
{
  int count = 0;
  while (*str && count < 4) {
    if (*str == ',') {
      count++;
    }
    str++;
  }
  return str;
}

// returns number of lines
static int convert(const char* src, char* dst)
{
  int n = 1;
  while (*src) {
    if (*src == '\\' && src[1] == 'N') {
      *dst++ = '\n';
      src += 2;
      n++;
    } else {
      *dst++ = *src++;
    }
  }
  *dst = 0;
  return n;
}

- (void)display:(CATextLayer *)layer time:(double)t
{
  if ([_frameQue isEmpty]) {
    return;
  }
  SubtitleFrame* s = [self get:t];
  if (s) {
    if (s.endTime <= t) {
      layer.string = @"";
      avsubtitle_free(s.sub);
      [_frameQue get];
    } else {
      char buf[2048];
      convert(findSub(s.ass), buf);
      layer.string = [NSString stringWithUTF8String:buf];
    }
  }
  if ([_frameQue count] < QSIZE / 3) {
    dispatch_semaphore_signal(_sema);
  }
}

@end
