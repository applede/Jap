//
//  VideoQueue.h
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>
#import "VideoQueue.h"

@interface Decoder : NSObject
{
  BOOL _quit;
  dispatch_semaphore_t _sema;

  AVStream *_video_st;
  AVFrame *_frame;
}

@property (readonly) VideoQueue* videoQ;

- (void)start;
- (void)remove;

@end
