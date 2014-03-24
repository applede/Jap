//
//  Decoder.h
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>
#import "VideoBuf.h"
#import "AudioBuf.h"
#import "SubtitleBuf.h"
#import "PacketQueue.h"

@interface Decoder : NSObject
{
  NSString* _path;
  
  BOOL _quit;
  dispatch_queue_t _decodeQ;
  dispatch_queue_t _readQ;
  dispatch_semaphore_t _readSema;

  AVFormatContext *_ic;
  int _video_stream;
  int _audio_stream;
  int _subtitle_stream;
  
  AudioBuf* _audioBuf;
  SubtitleBuf* _subtitleBuf;
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
