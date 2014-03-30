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

- (NSOpenGLContext *)openGLContextForPixelFormat:(NSOpenGLPixelFormat *)pixelFormat
{
  NSOpenGLContext* ctx = [super openGLContextForPixelFormat:pixelFormat];
  if (!_decoder) {
    _decoder = [[Decoder alloc] init];
  }
  [self initGL:ctx];
  self.needsDisplayOnBoundsChange = YES;
  self.backgroundColor = [[NSColor blackColor] CGColor];
  self.asynchronous = NO;
  return ctx;
}

void makeOrtho(GLfloat width, GLfloat height, GLfloat* mat)
{
  GLfloat left = 0;
  GLfloat right = width;
  GLfloat bottom = 0;
  GLfloat top = height;
  GLfloat near = -1;
  GLfloat far = 1;
  
  mat[0] = 2.0 / (right - left);
  mat[1] = 0;
  mat[2] = 0;
  mat[3] = 0;
  
  mat[4] = 0;
  mat[5] = 2.0 / (top - bottom);
  mat[6] = 0;
  mat[7] = 0;
  
  mat[8] = 0;
  mat[9] = 0;
  mat[10] = -2.0 / (far - near);
  mat[11] = 0;
  
  mat[12] = -(right + left) / (right - left);
  mat[13] = -(top + bottom) / (top - bottom);
  mat[14] = -(far + near) / (far - near);
  mat[15] = 1.0;
}

- (void)initGL:(NSOpenGLContext*)ctx
{
  [ctx makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[ctx setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
	glDisable(GL_DEPTH_TEST);
	glEnable(GL_TEXTURE_2D);
	
  glGenBuffers(1, &buffer_);
  glBindBuffer(GL_ARRAY_BUFFER, buffer_);
  glBufferData(GL_ARRAY_BUFFER, 16 * sizeof(GLfloat), NULL, GL_STATIC_DRAW);
}

- (BOOL)canDrawInOpenGLContext:(NSOpenGLContext *)context
                   pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
                  forLayerTime:(CFTimeInterval)lt displayTime:(const CVTimeStamp *)ts
{
  double t = [_decoder masterClock];
  return _decoder.videoBuf && [_decoder.videoBuf time:_current] <= t;
}

- (void)drawInOpenGLContext:(NSOpenGLContext *)context
                pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
               forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts;
{
  @autoreleasepool {
    [self load:_current];
    [self draw:_current];
    [_decoder displaySubtitle];
    [_decoder decodeVideoBuffer:_current + ADVANCE];
    _current++;
  }
}

- (void) load:(int)i
{
  [_decoder.videoBuf load:i];
  
//  // Bind the rectange texture
//  glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texIds[i % TEXTURE_COUNT][0]);
//  glTexParameterf(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_PRIORITY, 1.0 );
//  
//  // Set a CACHED or SHARED storage hint for requesting VRAM or AGP texturing respectively
//  // GL_STORAGE_PRIVATE_APPLE is the default and specifies normal texturing path
//  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_CACHED_APPLE);
//  
//  // Eliminate a data copy by the OpenGL framework using the Apple client storage extension
//  glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
//  
//  // Rectangle textures has its limitations compared to using POT textures, for example,
//  // Rectangle textures can't use mipmap filtering
//  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
//  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
//  
//  // Rectangle textures can't use the GL_REPEAT warp mode
//  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//  
//  glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
//  
//  // OpenGL likes the GL_BGRA + GL_UNSIGNED_INT_8_8_8_8_REV combination
//  glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA,
//               _decoder.videoBuf.width, _decoder.videoBuf.height, 0,
//               GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, [_decoder.videoBuf data:i]);
}

- (void) draw:(int)i
{
  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  
  [_decoder.videoBuf draw:i];
}

- (BOOL)frameChanged
{
  NSOpenGLContext* context = self.openGLContext;
  if (context && _decoder.videoBuf) {
    [self.openGLContext makeCurrentContext];
    [self reshape];
    return YES;
  }
  return NO;
}

- (void) reshape
{
  NSRect rect = self.bounds;
  CGFloat s = self.contentsScale;
  GLfloat vw = rect.size.width * s;
  GLfloat vh = rect.size.height * s;
	
  GLfloat w = _decoder.videoBuf.width;
  GLfloat h = _decoder.videoBuf.height;
#if 1
  GLuint program = _decoder.videoBuf.program;
  glUseProgram(program);
  GLint ortho = glGetUniformLocation(program, "Ortho");
  assert(ortho >= 0);
  GLfloat orthoMat[16];
  makeOrtho(vw, vh, orthoMat);
  glUniformMatrix4fv(ortho, 1, NO, orthoMat);
#endif
  [self calcRect];
  
  GLfloat x0 = _movieRect.origin.x;
  GLfloat y0 = _movieRect.origin.y;
  GLfloat x1 = _movieRect.origin.x + _movieRect.size.width;
  GLfloat y1 = _movieRect.origin.y + _movieRect.size.height;
  GLfloat vertices[16] = {
    x0, y0,   x0, y1,   x1, y1,   x1, y0,
//    0, 1,     0, 0,     1, 0,     1, 1
    0, h,     0, 0,     w, 0,     w, h
  };
  glBindBuffer(GL_ARRAY_BUFFER, buffer_);
  glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(vertices), vertices);
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
  
  _movieRect.origin.x = (viewW - dstW) / 2;
  _movieRect.origin.y = (viewH - dstH) / 2;
  _movieRect.size.width = dstW;
  _movieRect.size.height = dstH;
}

- (void)open:(NSString *)path
{
  [_decoder open:path];
  [self.openGLContext makeCurrentContext];
  [_decoder.videoBuf prepare:self.openGLContext.CGLContextObj];
  for (int i = 0; i < ADVANCE; ++i) {
    [_decoder decodeVideoBuffer:_current + i];
  }
  self.asynchronous = YES;
}

@end
