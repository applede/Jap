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
#define FRAME_SIZE  (TEXTURE_WIDTH * 4 * TEXTURE_HEIGHT)

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
    _size = FRAME_SIZE * TEXTURE_COUNT;
    _data = (GLubyte*)calloc(_size, sizeof(GLubyte));
    _width = TEXTURE_WIDTH;
    _height = TEXTURE_HEIGHT;
    for (int i = 0; i < TEXTURE_COUNT; i++) {
      _time[i] = DBL_MAX;
    }
  }
  return self;
}

- (void)dealloc
{
	// When using client storage, we should keep the data around until the textures are deleted
	if (_data) {
		free(_data);
		_data = nil;
	}
}

- (void)setDecoder:(Decoder *)decoder stream:(AVStream *)stream
{
  _decoder = decoder;
  _stream = stream;
}

- (GLubyte*)data:(int)i
{
  return &_data[FRAME_SIZE * mod(i)];
}

- (GLubyte *)dataY:(int)i
{
//  static GLubyte dummy[1920*1080];
//  memset(dummy, 0, sizeof(dummy));
//  return dummy;
  return _frame[mod(i)]->data[0];
}

- (GLubyte *)dataU:(int)i
{
//  static GLubyte dummy[1920*1080];
//  memset(dummy, 128, sizeof(dummy));
//  return dummy;
  return _frame[mod(i)]->data[1];
}

- (GLubyte *)dataV:(int)i
{
//  static GLubyte dummy[1920*1080];
//  memset(dummy, 255, sizeof(dummy));
//  return dummy;
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

- (CVPixelBufferRef)pixelBuf:(int)i
{
  return _pixelBuf[mod(i)];
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
  AVFrame *frame = av_frame_alloc();
  double pts;
  AVRational tb = _stream->time_base;
  
  while (!_quit && ![_decoder.videoQue isEmpty]) {
    if ([self getVideoFrame:frame packet:&pkt]) {
      pts = (frame->pts == AV_NOPTS_VALUE) ? NAN : frame->pts * av_q2d(tb);
      [self put:frame time:pts pos:av_frame_get_pkt_pos(frame) into:i];
//      av_frame_unref(frame);
      break;
    }
    av_free_packet(&pkt);
  }
  [_decoder checkQueue];

  av_free_packet(&pkt);
  if (0) {
    av_frame_free(&frame);
  }
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

- (void)put:(AVFrame *)frame time:(double)t pos:(int64_t)p into:(int)i
{
  if (_frame[mod(i)]) {
    av_frame_free(&_frame[mod(i)]);
  }
  _frame[mod(i)] = frame;
  assert(_frame[mod(i)]->data[0]);
  
  if (0) {
    _img_convert_ctx = sws_getCachedContext(_img_convert_ctx,
                                            frame->width, frame->height, frame->format,
                                            _width, _height,
                                            AV_PIX_FMT_BGRA, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    if (_img_convert_ctx == NULL) {
      NSLog(@"Cannot initialize the conversion context");
    }
    GLubyte* data[] = { [self data:i] };
    int linesize[] = { _width * 4 };
    sws_scale(_img_convert_ctx, (const uint8_t* const*)frame->data, frame->linesize, 0, _height,
              data, linesize);
  }
  [self setTime:t of:i];
  //  NSLog(@"decoded %d", i);
}

@end
