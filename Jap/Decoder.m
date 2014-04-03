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
#import "Packet.h"

#define PACKET_Q_SIZE 300

@implementation Decoder

- (id)init
{
  self = [super init];
  if (self) {
    _quit = NO;
    _videoQue = [[CircularQueue alloc] initSize:PACKET_Q_SIZE];
    _audioQue = [[CircularQueue alloc] initSize:PACKET_Q_SIZE];
    _subtitleQue = [[CircularQueue alloc] initSize:PACKET_Q_SIZE];
    _readQ = dispatch_queue_create("jap.read", DISPATCH_QUEUE_SERIAL);
    _readSema = dispatch_semaphore_create(0);
    av_register_all();
  }
  return self;
}

- (void)open:(NSString *)p
{
  _path = p;
  _quit = NO;
  [self readThread];
  while ([_videoQue count] < 16) {  // 16 packets are enough?
    usleep(100000);
  }
  while ([_audioQue count] < 16) {
    usleep(100000);
  }
  [_videoTrack start];
  [_audioTrack start];
  [_subtitleTrack start];
}

- (void)play
{
  [_audioTrack play];
}

- (void)pause
{
  [_audioTrack pause];
}

- (void)stop
{
  _quit = YES;
  [_audioTrack stop];
}

- (double)masterClock
{
  return [_audioTrack clock];
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
  AVCodecContext *avctx = _formatContext->streams[i]->codec;
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
  _formatContext->streams[i]->discard = AVDISCARD_DEFAULT;
  return _formatContext->streams[i];
}

/// @return nil if smi file does not exist

NSString* smiPath(NSString* path)
{
  NSString* filename = [path stringByDeletingPathExtension];
  NSString* smiPath = [filename stringByAppendingPathExtension:@"smi"];
  BOOL dir;
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:smiPath isDirectory:&dir];
  if (!exists || dir) {
    smiPath = nil;
  }
  return smiPath;
}

- (BOOL)internalOpen:(NSString*)filename
{
  _formatContext = NULL;
  int err = avformat_open_input(&_formatContext, [filename UTF8String], NULL, NULL);
  if (err < 0) {
    NSLog(@"avformat_open_input %d", err);
    return NO;
  }
  err = avformat_find_stream_info(_formatContext, NULL);
  if (err < 0) {
    NSLog(@"avformat_find_stream_info %d", err);
    return NO;
  }
  _videoStream = av_find_best_stream(_formatContext, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
  AVCodecContext* context = _formatContext->streams[_videoStream]->codec;
  if (context->codec_id == AV_CODEC_ID_H264) {
    _videoTrack = [[VideoTrackGPU alloc] initDecoder:self stream:_formatContext->streams[_videoStream]];
  } else {
    _videoTrack = [[VideoTrackCPU alloc] initDecoder:self stream:[self openStream:_videoStream]];
  }
  
  _audioStream = av_find_best_stream(_formatContext, AVMEDIA_TYPE_AUDIO, -1, _videoStream, NULL, 0);
  _audioTrack = [[AudioTrack alloc] initDecoder:self stream:[self openStream:_audioStream]];
  [_audioTrack prepare];

  NSString* smiP = smiPath(_path);
  _subtitleTrack = [[SubtitleTrackSMI alloc] initDecoder:self
                                                  stream:_formatContext->streams[_videoStream] path:smiP];
  if (_subtitleTrack) {
    _subtitleStream = -1;
  } else {
    _subtitleStream = av_find_best_stream(_formatContext, AVMEDIA_TYPE_SUBTITLE, -1,
                                          (_audioStream >= 0 ? _audioStream : _videoStream),
                                          NULL, 0);
    _subtitleTrack = [[SubtitleTrackEmbed alloc] initDecoder:self stream:[self openStream:_subtitleStream]];
  }
 
  while (!_quit) {
    while (![_videoQue isFull] && ![_audioQue isFull]) {
      Packet* packet = [[Packet alloc] init];
      int ret = av_read_frame(_formatContext, packet.packet);
      if (ret < 0) {
        NSLog(@"av_read_frame %d", ret);
      }
      if (packet.streamIndex == _videoStream)
        [_videoQue put:packet];
      else if (packet.streamIndex == _audioStream)
        [_audioQue put:packet];
      else if (packet.streamIndex == _subtitleStream)
        [_subtitleQue put:packet];
      // packet will be freed here as it goes out of scope
    }
    dispatch_semaphore_wait(_readSema, DISPATCH_TIME_FOREVER);
  }
  return YES;
}

- (void)close
{
  if (_formatContext) {
    avformat_close_input(&_formatContext);
  }
  [_audioTrack close];
}

- (void)checkQueue
{
  if ([_videoQue count] < PACKET_Q_SIZE / 3 ||
      [_audioQue count] < PACKET_Q_SIZE / 3 ||
      [_subtitleQue count] < PACKET_Q_SIZE / 3) {
    dispatch_semaphore_signal(_readSema);
  }
}

- (NSString *)subtitleString
{
  return [_subtitleTrack stringForTime:[self masterClock]];
}

@end
