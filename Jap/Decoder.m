//
//  Decoder.m
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <libavcodec/avcodec.h>
#import <libavutil/opt.h>
#import "Decoder.h"

#define PACKET_Q_SIZE 300

@implementation Decoder

- (id)init
{
  self = [super init];
  if (self) {
    quit_ = NO;
    _videoQue = [[PacketQueue alloc] initWithSize:PACKET_Q_SIZE];
    _audioQue = [[PacketQueue alloc] initWithSize:PACKET_Q_SIZE];
    _subtitleQue = [[PacketQueue alloc] initWithSize:PACKET_Q_SIZE];
//    _videoBuf = [[VideoBuf alloc] init];
//    audioBuf_ = [[AudioBuf alloc] init];
//    subtitleBuf_ = [[SubtitleBuf alloc] init];
    decodeQ_ = dispatch_queue_create("jap.decode", DISPATCH_QUEUE_SERIAL);
    readQ_ = dispatch_queue_create("jap.read", DISPATCH_QUEUE_SERIAL);
    readSema_ = dispatch_semaphore_create(0);
    av_register_all();
  }
  return self;
}

- (void)open:(NSString *)path
{
  path_ = path;
  quit_ = NO;
  [self readThread];
  while ([_videoQue count] < 16) {  // 16 packets are enough?
    usleep(100000);
  }
  while ([_audioQue count] < 16) {
    usleep(100000);
  }
  [audioBuf_ start];
  [subtitleBuf_ start];
}

- (void)stop
{
  quit_ = YES;
  [audioBuf_ stop];
}

- (double)masterClock
{
  return [audioBuf_ clock];
}

- (void)readThread
{
  dispatch_async(readQ_, ^{
    if (![self internalOpen:path_]) {
      [self close];
    }
  });
}

- (AVStream*)openStream:(int)i
{
  AVCodecContext *avctx = formatContext_->streams[i]->codec;
  AVCodec *codec = avcodec_find_decoder(avctx->codec_id);
  
  avctx->codec_id = codec->id;
  avctx->workaround_bugs = 1;
  av_codec_set_lowres(avctx, 0);
  avctx->error_concealment = 3;
  AVDictionary *opts = NULL;
  av_dict_set(&opts, "threads", "auto", 0);
  if (avctx->codec_type == AVMEDIA_TYPE_VIDEO || avctx->codec_type == AVMEDIA_TYPE_AUDIO)
    av_dict_set(&opts, "refcounted_frames", "1", 0);
  if (avcodec_open2(avctx, codec, &opts) < 0) {
    NSLog(@"avcodec_open2");
    return nil;
  }
  formatContext_->streams[i]->discard = AVDISCARD_DEFAULT;
  return formatContext_->streams[i];
}

- (BOOL)internalOpen:(NSString*)filename
{
  formatContext_ = NULL;
  int err = avformat_open_input(&formatContext_, [filename UTF8String], NULL, NULL);
  if (err < 0) {
    NSLog(@"avformat_open_input %d", err);
    return NO;
  }
  err = avformat_find_stream_info(formatContext_, NULL);
  if (err < 0) {
    NSLog(@"avformat_find_stream_info %d", err);
    return NO;
  }
  video_stream_ = av_find_best_stream(formatContext_, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
  AVCodecContext* context = formatContext_->streams[video_stream_]->codec;
  if (context->codec_id == AV_CODEC_ID_H264) {
    _videoBuf = [[VideoBufGPU alloc] initDecoder:self stream:formatContext_->streams[video_stream_]];
  } else {
    _videoBuf = [[VideoBufCPU alloc] initDecoder:self stream:[self openStream:video_stream_]];
  }
  
  audio_stream_ = av_find_best_stream(formatContext_, AVMEDIA_TYPE_AUDIO, -1, video_stream_, NULL, 0);
  audioBuf_ = [[AudioBuf alloc] initDecoder:self stream:[self openStream:audio_stream_]];
  [audioBuf_ prepare];

  subtitle_stream_ = av_find_best_stream(formatContext_, AVMEDIA_TYPE_SUBTITLE, -1,
                                         (audio_stream_ >= 0 ? audio_stream_ : video_stream_),
                                         NULL, 0);
  subtitleBuf_ = [[SubtitleBuf alloc] initDecoder:self stream:[self openStream:subtitle_stream_]];
  
  AVPacket pkt1, *pkt = &pkt1;
  while (!quit_) {
    while (![_videoQue isFull] && ![_audioQue isFull]) {
      int ret = av_read_frame(formatContext_, pkt);
      if (ret < 0) {
        NSLog(@"av_read_frame %d", ret);
      }
      if (pkt->stream_index == video_stream_)
        [_videoQue put:pkt];
      else if (pkt->stream_index == audio_stream_)
        [_audioQue put:pkt];
      else if (pkt->stream_index == subtitle_stream_)
        [_subtitleQue put:pkt];
      else
        av_free_packet(pkt);
    }
    dispatch_semaphore_wait(readSema_, DISPATCH_TIME_FOREVER);
  }
  return YES;
}

- (void)close
{
  if (formatContext_) {
    avformat_close_input(&formatContext_);
  }
  [audioBuf_ close];
}

- (void)decodeVideoBuffer:(int)i
{
  [_videoBuf setTime:DBL_MAX of:i];
  dispatch_async(decodeQ_, ^{
    @autoreleasepool {
      [_videoBuf decode:i];
    }
  });
}

- (void)checkQueue
{
  if ([_videoQue count] < PACKET_Q_SIZE / 3 ||
      [_audioQue count] < PACKET_Q_SIZE / 3 ||
      [_subtitleQue count] < PACKET_Q_SIZE / 3) {
    dispatch_semaphore_signal(readSema_);
  }
}

- (void)displaySubtitle
{
  [subtitleBuf_ display:_subtitle time:[self masterClock]];
}

@end
