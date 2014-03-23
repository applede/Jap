//
//  MyOpenGLLayer.m
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <OpenGL/gl.h>
#import "MyOpenGLLayer.h"

#define ADVANCE (TEXTURE_COUNT - 1)

@implementation MyOpenGLLayer

- (NSOpenGLPixelFormat *)openGLPixelFormatForDisplayMask:(uint32_t)mask
{
  return [super openGLPixelFormatForDisplayMask:mask];
//  NSOpenGLPixelFormatAttribute attrs[] = {
//		NSOpenGLPFAAccelerated,
//		NSOpenGLPFANoRecovery,
//		NSOpenGLPFADoubleBuffer,
//		NSOpenGLPFADepthSize, 0,
//    NSOpenGLPFAScreenMask, mask,
//		0
//  };
//	
//  NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
//  return pf;
}

- (NSOpenGLContext *)openGLContextForPixelFormat:(NSOpenGLPixelFormat *)pixelFormat
{
  NSOpenGLContext* ctx = [super openGLContextForPixelFormat:pixelFormat];
//  self.contentsScale = [self.view.window backingScaleFactor];
  if (!_decoder) {
    _decoder = [[Decoder alloc] init];
    [_decoder start];
    for (int i = 0; i < ADVANCE; ++i) {
      [_decoder decodeVideoBuffer:_current + i];
    }
  }
  [self initGL:ctx];
  self.asynchronous = YES;
  self.needsDisplayOnBoundsChange = YES;
  self.backgroundColor = [[NSColor blackColor] CGColor];
  return ctx;
}

- (void)releaseCGLContext:(CGLContextObj)ctx
{
	glDeleteTextures(TEXTURE_COUNT, texIds);
  [super releaseCGLContext:ctx];
}

- (void)initGL:(NSOpenGLContext*)ctx
{
  [ctx makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[ctx setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
	// Create OpenGL textures
	glGenTextures(TEXTURE_COUNT, texIds);
	
	// Enable the rectangle texture extenstion
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	
	// Eliminate a data copy by the OpenGL driver using the Apple texture range extension along with the rectangle texture extension
	// This specifies an area of memory to be mapped for all the textures. It is useful for tiled or multiple textures in contiguous memory.
	glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, _decoder.videoBuf.size, [_decoder.videoBuf data:0]);
	glDisable(GL_DEPTH_TEST);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glEnable(GL_UNPACK_CLIENT_STORAGE_APPLE);
  [self reshape];
}

- (BOOL)canDrawInOpenGLContext:(NSOpenGLContext *)context
                   pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
                  forLayerTime:(CFTimeInterval)lt displayTime:(const CVTimeStamp *)ts
{
  double t = [_decoder masterClock];
//  while ([_decoder.videoBuf time:_current + 1] <= t) {
//    NSLog(@"decode %d", _current + ADVANCE);
//    [_decoder decodeVideoBuffer:_current + ADVANCE];
//    _current++;
//  }
//  NSLog(@"can %d", _current);
  return [_decoder.videoBuf time:_current] <= t;
}

- (void)drawInOpenGLContext:(NSOpenGLContext *)context
                pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
               forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts;
{
  @autoreleasepool {
//    double t = [_decoder masterClock];
//    while ([_decoder.videoBuf time:_current + 1] <= t) {
//      [_decoder decodeVideoBuffer:_toDecode++];
//      _current++;
//    }
//    CGLLockContext([context CGLContextObj]);
//    [context makeCurrentContext];
//    if ([_decoder.videoBuf time:_current] <= t) {
      [self load:_current];
      [self draw:_current];
//    NSLog(@"draw %d", _current);
      [_decoder decodeVideoBuffer:_current + ADVANCE];
      _current++;
//    } else {
//      [self draw:_current - 1];
//    }
//    [super drawInOpenGLContext:context pixelFormat:pixelFormat forLayerTime:t displayTime:ts];
//    [context flushBuffer];
//    CGLUnlockContext([context CGLContextObj]);
  }
}

- (void) load:(int)i
{
//	CGLLockContext([[self openGLContext] CGLContextObj]);
//	[[self openGLContext] makeCurrentContext];
	// Enable the rectangle texture extenstion
//	glEnable(GL_TEXTURE_RECTANGLE_EXT);
//	glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, _buffer.size, [_buffer frontData]);
	
  // Bind the rectange texture
  glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texIds[i % TEXTURE_COUNT]);
  glTexParameterf(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_PRIORITY, 1.0 );
  
  // Set a CACHED or SHARED storage hint for requesting VRAM or AGP texturing respectively
  // GL_STORAGE_PRIVATE_APPLE is the default and specifies normal texturing path
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_CACHED_APPLE);
  
  // Eliminate a data copy by the OpenGL framework using the Apple client storage extension
//  glEnable( GL_UNPACK_CLIENT_STORAGE_APPLE );
  glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
		
  // Rectangle textures has its limitations compared to using POT textures, for example,
  // Rectangle textures can't use mipmap filtering
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		
  // Rectangle textures can't use the GL_REPEAT warp mode
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
			
  glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
			
  // OpenGL likes the GL_BGRA + GL_UNSIGNED_INT_8_8_8_8_REV combination
  glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA,
               _decoder.videoBuf.width, _decoder.videoBuf.height, 0,
               GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, [_decoder.videoBuf data:i]);
	
//	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
//	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void) draw:(int)i
{
	const GLfloat vertices[] = { _x1, _y1, _x1, _y2, _x2, _y2, _x2, _y1 };
	
  GLfloat w = _decoder.videoBuf.width;
  GLfloat h = _decoder.videoBuf.height;
	// Rectangle textures require non-normalized texture coordinates
	const GLfloat texcoords[] = { 0, h, 0, 0, w, 0, w, h };
	
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main thread
	// Add a mutex around to avoid the threads accessing the context simultaneously	when resizing
//	CGLLockContext([[self openGLContext] CGLContextObj]);
	
//	[[self openGLContext] makeCurrentContext];
	
  if (_clear > 0) {
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    _clear--;
  }
	
//	glEnable(GL_TEXTURE_RECTANGLE_EXT);
  glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texIds[i % TEXTURE_COUNT]);
	glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
		
  glVertexPointer(2, GL_FLOAT, 0, vertices);
  glDrawArrays(GL_QUADS, 0, 4);
	
//	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
	
//	[[self openGLContext] flushBuffer];
	
//	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)frameChanged
{
  NSOpenGLContext* context = self.openGLContext;
  if (context) {
    [self.openGLContext makeCurrentContext];
    [self reshape];
    _clear = 2;
  }
}

- (void) reshape
{
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main thread
	// Add a mutex around to avoid the threads accessing the context simultaneously when resizing
  NSRect rect = self.bounds;
  CGFloat s = self.contentsScale;
  rect.size.width *= s;
  rect.size.height *= s;
	glViewport(0, 0, rect.size.width, rect.size.height);
	
	glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(0, rect.size.width, 0, rect.size.height, -10.0f, 10.0f);
	glMatrixMode(GL_MODELVIEW);
	
  [self calcRect];
}

- (void)calcRect
{
  CGRect bounds = self.bounds;
  CGFloat s = self.contentsScale;
  bounds.size.width *= s;
  bounds.size.height *= s;
  
  int srcW = _decoder.videoBuf.width;
  int srcH = _decoder.videoBuf.height;
  GLfloat viewW = bounds.size.width;
  GLfloat viewH = bounds.size.height;

  GLfloat dstW = viewH * srcW / srcH;
  GLfloat dstH;

  if (dstW <= viewW) {
    dstH = viewH;
  } else {
    dstH = viewW * srcH / srcW;
    dstW = viewW;
  }
  
  _x1 = (viewW - dstW) / 2;
  _y1 = (viewH - dstH) / 2;
  _x2 = _x1 + dstW;
  _y2 = _y1 + dstH;
}

@end
