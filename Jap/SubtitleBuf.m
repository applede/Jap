//
//  SubtitleBuf.m
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "SubtitleBuf.h"
#import "Decoder.h"

@implementation SubtitleBuf

- (id)initDecoder:(Decoder *)decoder stream:(AVStream *)stream
{
  self = [super init];
  if (self) {
    _q = dispatch_queue_create("jap.subtitle", DISPATCH_QUEUE_SERIAL);
    _front = 0;
    _back = 0;
    _size = 32;
    _count = 0;
    _sub = calloc(_size, sizeof(*_sub));
    _time = calloc(_size, sizeof(*_time));
    _lock = [[NSLock alloc] init];
    _sema = dispatch_semaphore_create(0);
    _decoder = decoder;
    _stream = stream;
  }
  return self;
}

- (void)dealloc
{
  free(_sub);
  free(_time);
}

- (void)start
{
  dispatch_async(_q, ^{
    AVSubtitle* sub;
    int got_subtitle;
    AVPacket packet;
    double pts;
    
    while (!_quit) {
      @autoreleasepool {
        while (!_quit && ![_decoder.subtitleQue isEmpty] && ![self isFull]) {
          [_decoder.subtitleQue get:&packet];
          pts = 0;
          if (packet.pts != AV_NOPTS_VALUE)
            pts = av_q2d(_stream->time_base) * packet.pts;
          sub = [self back];
          avcodec_decode_subtitle2(_stream->codec, sub, &got_subtitle, &packet);
          if (got_subtitle) {
            if (sub->pts != AV_NOPTS_VALUE)
                pts = sub->pts / (double)AV_TIME_BASE;
            if (sub->rects) {
              [self put:pts];
            } else {
              assert(sub->rects);
            }
          }
          av_free_packet(&packet);
        }
        dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
      }
    }
  });
}

- (BOOL)isEmpty
{
  return _count == 0;
}

- (BOOL)isFull
{
  return _count == _size;
}

- (AVSubtitle*)back
{
  return &_sub[_back];
}

- (void)put:(double)time
{
  [_lock lock];
  assert(_count < _size);
  _time[_back] = time;
  _back = (_back + 1) % _size;
  _count++;
  [_lock unlock];
}

- (AVSubtitle*)get:(double)time startTime:(double*)s
{
  AVSubtitle* ret = nil;
  [_lock lock];
  if (_count > 0) {
    if (_time[_front] <= time) {
      ret = &_sub[_front];
      *s = _time[_front];
    }
  }
  [_lock unlock];
  return ret;
}

- (void)remove
{
  [_lock lock];
  avsubtitle_free(&_sub[_front]);
  _front = (_front + 1) % _size;
  _count--;
  [_lock unlock];
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
  if ([self isEmpty]) {
    return;
  }
  double start;
  AVSubtitle* sub = [self get:t startTime:&start];
  if (sub) {
    if (start + sub->end_display_time / 1000.0 <= t) {
      layer.string = @"";
      [self remove];
    } else {
      char buf[2048];
      convert(findSub(sub->rects[0]->ass), buf);
      layer.string = [NSString stringWithUTF8String:buf];
    }
  }
  if (_count < _size / 3) {
    dispatch_semaphore_signal(_sema);
  }
}

@end
