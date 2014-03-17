//
//  VideoQueue.m
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "FrameBuffer.h"

#define TEXTURE_WIDTH		1920
#define TEXTURE_HEIGHT	1080
#define FRAME_SIZE  (TEXTURE_WIDTH * 4 * TEXTURE_HEIGHT)

@implementation FrameBuffer

- (id)init
{
  self = [super init];
  if (self) {
    _size = FRAME_SIZE * TEXTURE_COUNT;
    _data = (GLubyte*)calloc(_size, sizeof(GLubyte));
    _width = TEXTURE_WIDTH;
    _height = TEXTURE_HEIGHT;
    _front = 0;
    _back = 0;
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

- (void)start
{
  _sema = dispatch_semaphore_create(0);
  dispatch_queue_t decodeQ = dispatch_queue_create("jap.decode", DISPATCH_QUEUE_SERIAL);
  dispatch_async(decodeQ, ^{
    while (!_quit) {
      while (!_quit && ![self isFull]) {
        [self decode];
      }
      
      dispatch_semaphore_wait(_sema, DISPATCH_TIME_FOREVER);
    }
  });
}

- (BOOL)isFull
{
  return _front == (_back + 1) % TEXTURE_COUNT;
}

- (BOOL)isEmpty
{
  return _front == _back;
}

- (void)decode
{
  int color[TEXTURE_COUNT][3] = {
    { 0xff, 0x00, 0x00 },
    { 0x00, 0xff, 0x00 },
    { 0x00, 0x00, 0xff },
    { 0xff, 0xff, 0x00 },
    { 0x00, 0xff, 0xff }
  };
  [self generateImageData:&_data[FRAME_SIZE * _back] color:color[0]];
  _back = (_back + 1) % TEXTURE_COUNT;
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
  for (int y = _count; y < _count + 8; ++y) {
    for (int x = 0; x < TEXTURE_WIDTH * 4; x += 4) {
      imageData[y * TEXTURE_WIDTH * 4 + x] = 0;
      imageData[y * TEXTURE_WIDTH * 4 + x + 1] = 0;
      imageData[y * TEXTURE_WIDTH * 4 + x + 2] = 0;
      imageData[y * TEXTURE_WIDTH * 4 + x + 3] = 0xff;
    }
  }
  _count++;
  if (_count > TEXTURE_HEIGHT - 8) {
    _count = 0;
  }
}

- (void)generate
{
	int i;
  int color[TEXTURE_COUNT][3] = {
    { 0xff, 0x00, 0x00 },
    { 0x00, 0xff, 0x00 },
    { 0x00, 0x00, 0xff },
    { 0xff, 0xff, 0x00 },
    { 0x00, 0xff, 0xff }
  };
	
	// This holds the data of all textures
	
	for (i = 0; i < TEXTURE_COUNT; i++)
	{
		// Point to the current texture
		GLubyte *imageData = &_data[FRAME_SIZE * i];
    [self generateImageData:imageData color:color[i]];
	}
}

- (GLubyte *)data:(int)i
{
  return &_data[FRAME_SIZE * i];
}

- (GLubyte*)frontData
{
  GLubyte* ret = &_data[FRAME_SIZE * _front];
  _front = (_front + 1) % TEXTURE_COUNT;
  dispatch_semaphore_signal(_sema);
  return ret;
}

@end
