//
//  VideoQueue.h
//  Jap
//
//  Created by Jake Song on 3/17/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

@class Decoder;

#define TEXTURE_COUNT		5

static inline int mod(int x)
{
  assert(x >= 0);
  return x % TEXTURE_COUNT;
}

@interface VideoBuf : NSObject
{
  BOOL quit_;
  Decoder* decoder_;
  AVStream* stream_;
  GLuint program_;
  int width_;
  int height_;
  
  double time_[TEXTURE_COUNT];
}

- (int)width;
- (int)height;

- (GLuint)program;
- (void)compileVertex:(const char*)vertexSrc fragment:(const char*)fragmentSrc;

- (void)prepare:(CGLContextObj)cgl;

- (double)time:(int)i;
- (void)setTime:(double)t of:(int)i;

- (void)decode:(int)i;
- (void)load:(int)i;
- (void)draw:(int)i;

@end
