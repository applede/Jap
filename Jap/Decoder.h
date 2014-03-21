//
//  Decoder.h
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <libavformat/avformat.h>
#import "VideoQueue.h"
#import "AudioQueue.h"
#import "PacketQueue.h"

typedef struct {
    int freq;
    int channels;
    int64_t channel_layout;
    enum AVSampleFormat fmt;
    int frame_size;
    int bytes_per_sec;
} AudioParams;

@interface Decoder : NSObject
{
  BOOL _quit;
  dispatch_queue_t _decodeQ;
  dispatch_queue_t _readQ;
  dispatch_semaphore_t _readSema;

  struct SwsContext *_img_convert_ctx;
  AVStream *_video_st;
  AVStream *_audio_st;
  int _video_stream;
  int _audio_stream;
  AVFormatContext *_ic;
  PacketQueue* _videoPacketQ;
  PacketQueue* _audioPacketQ;
  
  AudioComponentInstance _audioC;
  AudioQueue* _audioQ;
  
  AVPacket _audio_pkt_temp;
  AVPacket _audio_pkt;
  int _audio_buf_frames_pending;
  AVFrame *_frame;
  int _paused;
  int _audio_finished;
  int _audio_pkt_temp_serial;
  int64_t _audio_frame_next_pts;
  AudioParams _audio_src;
  AudioParams _audio_tgt;
  struct SwrContext *_swr_ctx;
  uint8_t *_audio_buf;
  uint8_t *_audio_buf1;
  unsigned int _audio_buf1_size;
  double _audio_clock;
  int _audio_clock_serial;
  int _audio_buf_index;
  int _audio_buf_size;
}

@property (readonly) VideoQueue* videoQ;

- (void)start;
- (void)decodeTask:(int)i;

@end
