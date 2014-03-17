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
    _size = FRAME_SIZE * FRAME_COUNT;
    _data = (GLubyte*)calloc(_size, sizeof(GLubyte));
    _width = TEXTURE_WIDTH;
    _height = TEXTURE_HEIGHT;
    _front = 0;
    _back = 0;
    _count = 0;
    _lock = [[NSLock alloc] init];
    _frameCount = 0;
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

- (BOOL)isFull
{
  return _count == FRAME_COUNT;
}

- (BOOL)isEmpty
{
  return _count == 0;
}

- (GLubyte*)frontData
{
  return &_data[FRAME_SIZE * _front];
}

- (GLubyte*)backData
{
  return &_data[FRAME_SIZE * _back];
}

- (double)time
{
  if ([self isEmpty]) {
    return DBL_MAX;
  }
  return _time[_front];
}

- (void)remove
{
  [_lock lock];
  _front = (_front + 1) % FRAME_COUNT;
  _count--;
  [_lock unlock];
}

- (void)add:(double)t
{
  [_lock lock];
  _time[_back] = t;
  _back = (_back + 1) % FRAME_COUNT;
  _count++;
  [_lock unlock];
}

- (void)generateImageData:(GLubyte*)imageData color:(int*)color
{
  for (int y = 0; y < TEXTURE_HEIGHT; ++y) {
    for (int x = 0; x < TEXTURE_WIDTH * 4; x += 4) {
      imageData[y * TEXTURE_WIDTH * 4 + x] = color[0];
      imageData[y * TEXTURE_WIDTH * 4 + x + 1] = color[1];
      imageData[y * TEXTURE_WIDTH * 4 + x + 2] = color[2];
      imageData[y * TEXTURE_WIDTH * 4 + x + 3] = 0xff;
    }
  }
  int h = 32;
  int y0 = _frameCount % (TEXTURE_HEIGHT - h);
  for (int y = y0; y < y0 + h; ++y) {
    for (int x = 0; x < TEXTURE_WIDTH * 4; x += 4) {
      imageData[y * TEXTURE_WIDTH * 4 + x] = 0;
      imageData[y * TEXTURE_WIDTH * 4 + x + 1] = 0;
      imageData[y * TEXTURE_WIDTH * 4 + x + 2] = 0;
      imageData[y * TEXTURE_WIDTH * 4 + x + 3] = 0xff;
    }
  }
}

- (void)generateDebugData
{
  int color[FRAME_COUNT][3] = {
    { 0xff, 0x00, 0x00 },
    { 0x00, 0xff, 0x00 },
    { 0x00, 0x00, 0xff },
    { 0xff, 0xff, 0x00 },
    { 0x00, 0xff, 0xff }
  };
  [self generateImageData:[self backData] color:color[0]];
  [self add:_frameCount * 1.0/10.0];
  _frameCount++;
}

@end
