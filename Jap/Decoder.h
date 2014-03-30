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
#import "CircularQueue.h"

@interface Decoder : NSObject
{
  NSString* _path;
  
  BOOL _quit;
  dispatch_queue_t _readQ;
  dispatch_semaphore_t _readSema;

  AVFormatContext *_formatContext;
  int _video_stream;
  int _audio_stream;
  int _subtitle_stream;
  
  AudioBuf* _audioBuf;
  SubtitleBuf* _subtitleBuf;
}

@property (readonly) CircularQueue* videoQue;
@property (readonly) CircularQueue* audioQue;
@property (readonly) CircularQueue* subtitleQue;
@property (readonly) VideoBuf* videoBuf;
@property (weak) CATextLayer* subtitle;

- (void)open:(NSString*)path;
- (void)checkQueue;
- (double)masterClock;
- (void)displaySubtitle;

@end
