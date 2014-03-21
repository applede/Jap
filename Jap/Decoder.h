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
  
  VideoBuf* _videoBuf;
  AudioBuf* _audioBuf;
}

@property PacketQueue* videoQ;
@property PacketQueue* audioQ;

- (void)start;
- (void)checkQueue;

// video
- (int)width;
- (int)height;
- (int)videoBufferSize;
- (void)decodeVideoBuffer:(int)i;
- (GLubyte*)dataOfVideoBuffer:(int)i;
- (double)timeOfVideoBuffer:(int)i;

@end
