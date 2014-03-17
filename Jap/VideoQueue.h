//
//  VideoQueue.h
//  Jap
//
//  Created by Jake Song on 3/17/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

#define FRAME_COUNT		5

@interface VideoQueue : NSObject
{
  NSLock* _lock;
  int _front;
  int _back;
  int _count;
  
  double _time[FRAME_COUNT];
  GLubyte* _data;
  
  int _frameCount;  // for debugging
}

@property int size;
@property int width;
@property int height;

- (BOOL)isFull;
- (void)add:(double)t;
- (void)remove;
- (double)time;
- (GLubyte*)frontData;
- (GLubyte*)backData;
- (void)generateDebugData;

@end
