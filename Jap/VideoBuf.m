//
//  VideoQueue.m
//  Jap
//
//  Created by Jake Song on 3/17/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <libswscale/swscale.h>
#import "VideoBuf.h"
#import "Decoder.h"

#define TEXTURE_WIDTH		1920
#define TEXTURE_HEIGHT	1080

static inline int mod(int x)
{
  assert(x >= 0);
  return x % TEXTURE_COUNT;
}

@implementation VideoBuf

- init
{
  self = [super init];
  if (self) {
    _width = TEXTURE_WIDTH;
    _height = TEXTURE_HEIGHT;
    _frameSize = avpicture_get_size(AV_PIX_FMT_YUV420P, _width, _height);
    _size = _frameSize * TEXTURE_COUNT;
    _data = calloc(TEXTURE_COUNT, _frameSize);
    for (int i = 0; i < TEXTURE_COUNT; i++) {
      _time[i] = DBL_MAX;
      _frame[i] = av_frame_alloc();
      avpicture_fill((AVPicture*)_frame[i], &_data[_frameSize * i], AV_PIX_FMT_YUV420P, _width, _height);
    }
  }
  return self;
}

- (void)dealloc
{
  for (int i = 0; i < TEXTURE_COUNT; i++) {
    av_frame_free(&_frame[i]);
  }
  free(_data);
}

- (void)setDecoder:(Decoder *)decoder stream:(AVStream *)stream
{
  _decoder = decoder;
  _stream = stream;
}

- (GLubyte *)dataY:(int)i
{
  return _frame[mod(i)]->data[0];
}

- (GLubyte *)dataU:(int)i
{
  return _frame[mod(i)]->data[1];
}

- (GLubyte *)dataV:(int)i
{
  return _frame[mod(i)]->data[2];
}

- (int)strideY:(int)i
{
  return _frame[mod(i)]->linesize[0];
}

- (int)strideU:(int)i
{
  return _frame[mod(i)]->linesize[1];
}

- (int)strideV:(int)i
{
  return _frame[mod(i)]->linesize[2];
}

- (double)time:(int)i
{
  return _time[mod(i)];
}

- (void)setTime:(double)t of:(int)i
{
  _time[mod(i)] = t;
}

- (void)decode:(int)i
{
  AVPacket pkt = { 0 };
  AVFrame *frame = _frame[mod(i)];
  double pts;
  AVRational tb = _stream->time_base;
  
  while (!_quit && ![_decoder.videoQue isEmpty]) {
    if ([self getVideoFrame:frame packet:&pkt]) {
      pts = (frame->pts == AV_NOPTS_VALUE) ? NAN : frame->pts * av_q2d(tb);
      [self putTime:pts pos:av_frame_get_pkt_pos(frame) into:i];
//      av_frame_unref(frame);
      break;
    }
    av_free_packet(&pkt);
  }
  [_decoder checkQueue];

  av_free_packet(&pkt);
}

- (BOOL)getVideoFrame:(AVFrame*)frame packet:(AVPacket*)pkt
{
  [_decoder.videoQue get:pkt];
  int got_picture = NO;
  if (avcodec_decode_video2(_stream->codec, frame, &got_picture, pkt) < 0) {
    NSLog(@"avcodec_decode_video2");
    return NO;
  }
  if (got_picture) {
    double dpts = NAN;
    
    frame->pts = av_frame_get_best_effort_timestamp(frame);
    
    if (frame->pts != AV_NOPTS_VALUE)
      dpts = av_q2d(_stream->time_base) * frame->pts;
    
    return YES;
  }
  return NO;
}

- (void)putTime:(double)t pos:(int64_t)p into:(int)i
{
//    _img_convert_ctx = sws_getCachedContext(_img_convert_ctx,
//                                            frame->width, frame->height, frame->format,
//                                            _width, _height,
//                                            AV_PIX_FMT_BGRA, SWS_FAST_BILINEAR, NULL, NULL, NULL);
//    if (_img_convert_ctx == NULL) {
//      NSLog(@"Cannot initialize the conversion context");
//    }
//    GLubyte* data[] = { [self data:i] };
//    int linesize[] = { _width * 4 };
//    sws_scale(_img_convert_ctx, (const uint8_t* const*)frame->data, frame->linesize, 0, _height,
//              data, linesize);
  [self setTime:t of:i];
  //  NSLog(@"decoded %d", i);
}

@end
