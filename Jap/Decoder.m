//
//  Decoder.m
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <libavcodec/avcodec.h>
#import <libswscale/swscale.h>
#import <libavutil/opt.h>
#import "Decoder.h"

#define VIDEO_PACKET_Q_SIZE 300

@implementation Decoder

- (id)init
{
  self = [super init];
  if (self) {
    _quit = NO;
    _videoPacketQ = [[PacketQueue alloc] initWithSize:VIDEO_PACKET_Q_SIZE];
    _videoQ = [[VideoQueue alloc] init];
    _decodeQ = dispatch_queue_create("jap.decode", DISPATCH_QUEUE_SERIAL);
    _readQ = dispatch_queue_create("jap.read", DISPATCH_QUEUE_SERIAL);
    _readSema = dispatch_semaphore_create(0);
  }
  return self;
}

- (void)start
{
  av_register_all();
  _sws_opts = sws_getContext(16, 16, 0, 16, 16, 0, SWS_BICUBIC, NULL, NULL, NULL);
  [self readThread];
  while ([_videoPacketQ count] < VIDEO_PACKET_Q_SIZE / 2) {
    usleep(100000);
  }
}

- (void)readThread
{
  dispatch_async(_readQ, ^{
    if (![self open:@"/Users/apple/hobby/test_jamp/movie/5 Centimeters Per Second (2007)/5 Centimeters Per Second.mkv"]) {
      [self close];
    }
  });
}

- (BOOL)open:(NSString*)filename
{
  _ic = avformat_alloc_context();
  int err = avformat_open_input(&_ic, [filename UTF8String], NULL, NULL);
  if (err < 0) {
    NSLog(@"avformat_open_input %d", err);
    return NO;
  }
  err = avformat_find_stream_info(_ic, NULL);
  if (err < 0) {
    NSLog(@"avformat_find_stream_info %d", err);
    return NO;
  }
  _video_stream = av_find_best_stream(_ic, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
  AVCodecContext *avctx = _ic->streams[_video_stream]->codec;
  AVCodec *codec = avcodec_find_decoder(avctx->codec_id);
  avctx->codec_id = codec->id;
  avctx->workaround_bugs = 1;
  av_codec_set_lowres(avctx, 0);
  avctx->error_concealment = 3;
  AVDictionary *opts = NULL;
  if (avctx->codec_type == AVMEDIA_TYPE_VIDEO || avctx->codec_type == AVMEDIA_TYPE_AUDIO)
    av_dict_set(&opts, "refcounted_frames", "1", 0);
  if (avcodec_open2(avctx, codec, &opts) < 0) {
    return NO;
  }
  _ic->streams[_video_stream]->discard = AVDISCARD_DEFAULT;
  _video_st = _ic->streams[_video_stream];
  AVPacket pkt1, *pkt = &pkt1;
  while (!_quit) {
    while (![_videoPacketQ isFull]) {
      int ret = av_read_frame(_ic, pkt);
      if (ret < 0) {
        NSLog(@"av_read_frame %d", ret);
      }
      if (pkt->stream_index == _video_stream)
        [_videoPacketQ put:pkt];
      else
        av_free_packet(pkt);
    }
    dispatch_semaphore_wait(_readSema, DISPATCH_TIME_FOREVER);
  }
  return YES;
}

- (void)close
{
  if (_ic) {
    avformat_close_input(&_ic);
  }
}

- (void)decodeTask:(int)i
{
  [_videoQ setTime:DBL_MAX of:i];
  dispatch_async(_decodeQ, ^{
    @autoreleasepool {
      [self decode:i];
    }
  });
}

- (void)decode:(int)i
{
  AVPacket pkt = { 0 };
  AVFrame *frame = av_frame_alloc();
  double pts;
  double duration;
  AVRational tb = _video_st->time_base;
  AVRational frame_rate = av_guess_frame_rate(_ic, _video_st, NULL);
  
  while (!_quit && ![_videoPacketQ isEmpty]) {
    if ([self getVideoFrame:frame packet:&pkt]) {
      duration = (frame_rate.num && frame_rate.den ? av_q2d((AVRational){frame_rate.den, frame_rate.num}) : 0);
      pts = (frame->pts == AV_NOPTS_VALUE) ? NAN : frame->pts * av_q2d(tb);
      //    queue_picture(is, frame, pts, duration, av_frame_get_pkt_pos(frame), serial);
      [self put:frame time:pts duration:duration pos:av_frame_get_pkt_pos(frame) into:i];
      av_frame_unref(frame);
      break;
    }
    av_free_packet(&pkt);
  }
  if ([_videoPacketQ count] < VIDEO_PACKET_Q_SIZE / 3) {
    dispatch_semaphore_signal(_readSema);
  }

  av_free_packet(&pkt);
  av_frame_free(&frame);
}

- (BOOL)getVideoFrame:(AVFrame*)frame packet:(AVPacket*)pkt
{
  [_videoPacketQ get:pkt];
  int got_picture = NO;
  if (avcodec_decode_video2(_video_st->codec, frame, &got_picture, pkt) < 0) {
    NSLog(@"avcodec_decode_video2");
    return NO;
  }
  if (got_picture) {
    double dpts = NAN;
    
    frame->pts = av_frame_get_best_effort_timestamp(frame);
    
    if (frame->pts != AV_NOPTS_VALUE)
      dpts = av_q2d(_video_st->time_base) * frame->pts;
    
    frame->sample_aspect_ratio = av_guess_sample_aspect_ratio(_ic, _video_st, frame);
    return YES;
  }
  return NO;
}

- (void)put:(AVFrame *)frame time:(double)t duration:(double)d pos:(int64_t)p into:(int)i
{
  static int64_t sws_flags = SWS_BICUBIC;
  
  av_opt_get_int(_sws_opts, "sws_flags", 0, &sws_flags);
  
  int w = _videoQ.width;
  int h = _videoQ.height;
  _img_convert_ctx = sws_getCachedContext(_img_convert_ctx,
                                          frame->width, frame->height, frame->format, w, h,
                                          AV_PIX_FMT_BGRA, (int)sws_flags, NULL, NULL, NULL);
  if (_img_convert_ctx == NULL) {
    NSLog(@"Cannot initialize the conversion context");
  }
  GLubyte* data[] = { [_videoQ data:i] };
  int linesize[] = { _videoQ.width * 4 };
  sws_scale(_img_convert_ctx, (const uint8_t* const*)frame->data, frame->linesize, 0, h, data, linesize);
  [_videoQ setTime:t of:i];
}

@end
