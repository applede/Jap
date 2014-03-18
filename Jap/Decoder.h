//
//  Decoder.h
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>
#import "VideoQueue.h"
#import "PacketQueue.h"

@interface Decoder : NSObject
{
  BOOL _quit;
  dispatch_queue_t _decodeQ;
  dispatch_queue_t _readQ;
  dispatch_semaphore_t _readSema;

  struct SwsContext *_sws_opts;
  struct SwsContext *_img_convert_ctx;
  AVStream *_video_st;
  int _video_stream;
  AVFormatContext *_ic;
  PacketQueue* _videoPacketQ;
}

@property (readonly) VideoQueue* videoQ;

- (void)start;
- (void)decodeTask:(int)i;

@end
