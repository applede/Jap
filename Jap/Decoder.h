//
//  Decoder.h
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>
#import "VideoBufCPU.h"
#import "VideoBufGPU.h"
#import "AudioBuf.h"
#import "SubtitleBuf.h"
#import "PacketQueue.h"

@interface Decoder : NSObject
{
  NSString* path_;
  
  BOOL quit_;
  dispatch_queue_t decodeQ_;
  dispatch_queue_t readQ_;
  dispatch_semaphore_t readSema_;

  AVFormatContext *formatContext_;
  int video_stream_;
  int audio_stream_;
  int subtitle_stream_;
  
  AudioBuf* audioBuf_;
  SubtitleBuf* subtitleBuf_;
}

@property (readonly) PacketQueue* videoQue;
@property (readonly) PacketQueue* audioQue;
@property (readonly) PacketQueue* subtitleQue;
@property (readonly) VideoBuf* videoBuf;
@property (weak) CATextLayer* subtitle;

- (void)open:(NSString*)path;
- (void)checkQueue;
- (double)masterClock;
- (void)decodeVideoBuffer:(int)i;
- (void)displaySubtitle;

@end
