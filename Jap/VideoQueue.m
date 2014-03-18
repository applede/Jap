//
//  VideoQueue.m
//  Jap
//
//  Created by Jake Song on 3/17/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "VideoQueue.h"

#define TEXTURE_WIDTH		1920
#define TEXTURE_HEIGHT	1080
#define FRAME_SIZE  (TEXTURE_WIDTH * 4 * TEXTURE_HEIGHT)

@implementation VideoQueue

- init
{
  self = [super init];
  if (self) {
    _size = FRAME_SIZE * TEXTURE_COUNT;
    _data = (GLubyte*)calloc(_size, sizeof(GLubyte));
    _width = TEXTURE_WIDTH;
    _height = TEXTURE_HEIGHT;
  }
  return self;
}

- (void)dealloc
{
	// When using client storage, we should keep the data around until the textures are deleted
	if (_data) {
		free(_data);
		_data = nil;
	}
}

- (GLubyte*)data:(int)i
{
  return &_data[FRAME_SIZE * i];
}

- (double)time:(int)i
{
  return _time[i];
}

- (void)setTime:(double)t of:(int)i
{
  _time[i] = t;
}

@end
