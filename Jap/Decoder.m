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
    _quit = NO;
    _videoQue = [[PacketQueue alloc] initWithSize:PACKET_Q_SIZE];
    _audioQue = [[PacketQueue alloc] initWithSize:PACKET_Q_SIZE];
    _videoBuf = [[VideoBuf alloc] init];
    _audioBuf = [[AudioBuf alloc] init];
    _decodeQ = dispatch_queue_create("jap.decode", DISPATCH_QUEUE_SERIAL);
    _readQ = dispatch_queue_create("jap.read", DISPATCH_QUEUE_SERIAL);
    _readSema = dispatch_semaphore_create(0);
    av_register_all();
  }
  return self;
}

- (void)open:(NSString *)path
{
  _path = path;
  _quit = NO;
  [self readThread];
  while ([_videoQue count] < 16) {  // 16 packets are enough?
    usleep(100000);
  }
  while ([_audioQue count] < 16) {
    usleep(100000);
  }
  [_audioBuf start];
}

- (void)stop
{
  _quit = YES;
  [_audioBuf stop];
}

- (double)masterClock
{
  return [_audioBuf clock];
}

- (void)readThread
{
  dispatch_async(_readQ, ^{
    if (![self internalOpen:_path]) {
      [self close];
    }
  });
}

- (AVStream*)openStream:(int)i
{
  AVCodecContext *avctx = _ic->streams[i]->codec;
  AVCodec *codec = avcodec_find_decoder(avctx->codec_id);
  avctx->codec_id = codec->id;
  avctx->workaround_bugs = 1;
  av_codec_set_lowres(avctx, 0);
  avctx->error_concealment = 3;
  AVDictionary *opts = NULL;
  if (avctx->codec_type == AVMEDIA_TYPE_VIDEO || avctx->codec_type == AVMEDIA_TYPE_AUDIO)
    av_dict_set(&opts, "refcounted_frames", "1", 0);
  if (avcodec_open2(avctx, codec, &opts) < 0) {
    NSLog(@"avcodec_open2");
    return nil;
  }
  _ic->streams[i]->discard = AVDISCARD_DEFAULT;
  return _ic->streams[i];
}

- (BOOL)internalOpen:(NSString*)filename
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
  [_videoBuf setDecoder:self stream:[self openStream:_video_stream]];
  
  _audio_stream = av_find_best_stream(_ic, AVMEDIA_TYPE_AUDIO, -1, _video_stream, NULL, 0);
  [_audioBuf setDecoder:self stream:[self openStream:_audio_stream]];
  [_audioBuf prepare];
  
  AVPacket pkt1, *pkt = &pkt1;
  while (!_quit) {
    while (![_videoQue isFull] && ![_audioQue isFull]) {
      int ret = av_read_frame(_ic, pkt);
      if (ret < 0) {
        NSLog(@"av_read_frame %d", ret);
      }
      if (pkt->stream_index == _video_stream)
        [_videoQue put:pkt];
      else if (pkt->stream_index == _audio_stream)
        [_audioQue put:pkt];
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
  [_audioBuf close];
}

- (void)decodeVideoBuffer:(int)i
{
  [_videoBuf setTime:DBL_MAX of:i];
  dispatch_async(_decodeQ, ^{
    @autoreleasepool {
      [_videoBuf decode:i];
    }
  });
}

- (void)checkQueue
{
  if ([_videoQue count] < PACKET_Q_SIZE / 3 || [_audioQue count] < PACKET_Q_SIZE / 3) {
    dispatch_semaphore_signal(_readSema);
  }
}

@end
