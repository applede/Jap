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
#import "PacketQueue.h"

@interface Decoder : NSObject
{
  BOOL _quit;
  dispatch_queue_t _decodeQ;
  
  dispatch_queue_t _readQ;
  dispatch_semaphore_t _readSema;

  AVFormatContext *_ic;
  int _video_stream;
  int _audio_stream;
  
  AudioBuf* _audioBuf;
}

@property (readonly) PacketQueue* videoQue;
@property (readonly) PacketQueue* audioQue;
@property (readonly) VideoBuf* videoBuf;

- (void)start;
- (void)checkQueue;
- (double)masterClock;
- (void)decodeVideoBuffer:(int)i;

@end
