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
//  [self initGL:ctx];
  self.needsDisplayOnBoundsChange = YES;
  self.backgroundColor = [[NSColor blackColor] CGColor];
//  CVReturn r = CVOpenGLTextureCacheCreate(0, 0, [ctx CGLContextObj], [pixelFormat CGLPixelFormatObj],
//                                          0, &_textureCache);
//  if (r != kCVReturnSuccess) {
//    NSLog(@"CVOpenGLTextureCacheCreate");
//  }
//  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//  _ciContext = [CIContext contextWithCGLContext:[ctx CGLContextObj] pixelFormat:[pixelFormat CGLPixelFormatObj]
//                                     colorSpace:colorSpace options:0];
//  CGColorSpaceRelease(colorSpace);
  return ctx;
}

GLuint compileShader(GLenum type, const GLchar* src)
{
  GLuint shader = glCreateShader(type);
  glShaderSource(shader, 1, &src, NULL);
  glCompileShader(shader);
  GLint compile_ok = 0;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compile_ok);
  if (!compile_ok) {
    NSLog(@"compile failed");
  }
  char log[2048];
  int logLen = 0;
  glGetShaderInfoLog(shader, sizeof(log), &logLen, log);
  if (logLen > 0) {
    NSLog(@"%s", log);
  }
  return shader;
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

GLuint createTexture(GLenum unit, GLsizei width, GLsizei height)
{
  GLuint texture = 0;
  
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  
//  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
//  glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  // This is necessary for non-power-of-two textures
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//  glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
  
  glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, width, height, 0, GL_RED, GL_UNSIGNED_BYTE, NULL);
  return texture;
}

void loadTexture(GLuint texture, GLsizei width, GLsizei height, GLubyte* data, int stride)
{
  glBindTexture(GL_TEXTURE_2D, texture);
  glPixelStorei(GL_UNPACK_ROW_LENGTH, stride);
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_RED, GL_UNSIGNED_BYTE, data);
}

- (void)initGL:(NSOpenGLContext*)ctx
{
  [ctx makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[ctx setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
//  if (texIds[0]) {
//    glDeleteTextures(TEXTURE_COUNT, texIds);
//  }
	// Create OpenGL textures
//	glGenTextures(TEXTURE_COUNT, texIds);
	
	// Enable the rectangle texture extenstion
	glEnable(GL_TEXTURE_2D);
	
	// Eliminate a data copy by the OpenGL driver using the Apple texture range extension along with the rectangle texture extension
	// This specifies an area of memory to be mapped for all the textures. It is useful for tiled or multiple textures in contiguous memory.
//	glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, _decoder.videoBuf.size, [_decoder.videoBuf data:0]);
	glDisable(GL_DEPTH_TEST);
//	glEnableClientState(GL_VERTEX_ARRAY);
//	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
//  glEnable(GL_UNPACK_CLIENT_STORAGE_APPLE);
  
  //: Y Texture
  if (texIds[0][0]) glDeleteTextures(1, &texIds[0][0]);
  texIds[0][0] = createTexture(GL_TEXTURE0, _decoder.videoBuf.width, _decoder.videoBuf.height);
  
  //: U Texture
  if (texIds[0][1]) glDeleteTextures(1, &texIds[0][1]);
  texIds[0][1] = createTexture(GL_TEXTURE1, _decoder.videoBuf.width / 2, _decoder.videoBuf.height / 2);
  
  //: V Texture
  if (texIds[0][2]) glDeleteTextures(1, &texIds[0][2]);
  texIds[0][2] = createTexture(GL_TEXTURE2, _decoder.videoBuf.width / 2, _decoder.videoBuf.height / 2);
  
  glGenBuffers(1, &_buffer);
//  glBindBuffer(GL_ARRAY_BUFFER, _buffer);
//  glBufferData(GL_ARRAY_BUFFER, 16 * sizeof(GLfloat), NULL, GL_STATIC_DRAW);
//  glEnableClientState(GL_VERTEX_ARRAY);
//  glVertexPointer(2, GL_FLOAT, 0, 0);
//  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
//  glTexCoordPointer(2, GL_FLOAT, 0, (char*)0 + 8 * sizeof(GLfloat));
  
  const char* vertexSrc =
  "#version 120\n"
  "attribute vec2 Position;\n"
  "attribute vec2 TexCoordIn;\n"
  "varying vec2 TexCoordOut;\n"
  "uniform mat4 Ortho;\n"
  "void main()\n"
  "{\n"
  "  gl_Position = Ortho * vec4(Position, 0, 1);"
  "  TexCoordOut = TexCoordIn;"
  "}";
  const char* fragmentSrc =
  "#version 120\n"
  "uniform sampler2D sampler0;"
  "uniform sampler2D sampler1;"
  "uniform sampler2D sampler2;"
  "varying vec2 TexCoordOut;"
  "void main(void)"
  "{"
  "  float y = texture2D(sampler0, TexCoordOut).r;"
  "  float u = texture2D(sampler1, TexCoordOut).r - 0.5;"
  "  float v = texture2D(sampler2, TexCoordOut).r - 0.5;"
  "  float r = y + 1.13983 * v;"
  "  float g = y - 0.39465 * u - 0.58060 * v;"
  "  float b = y + 2.03211 * u;"
  "  gl_FragColor = vec4(r, g, b, 1.0);"
  "}";
  
  _vertexShader = compileShader(GL_VERTEX_SHADER, vertexSrc);
  _fragmentShader = compileShader(GL_FRAGMENT_SHADER, fragmentSrc);
  
  _program = glCreateProgram();
  glAttachShader(_program, _vertexShader);
  int logLen;
  glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &logLen);
  if (logLen > 0) {
    char log[2048];
    glGetProgramInfoLog(_program, sizeof(log), &logLen, log);
    NSLog(@"%s", log);
  }
  glAttachShader(_program, _fragmentShader);
  glLinkProgram(_program);
  
  glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &logLen);
  if (logLen > 0) {
    char log[2048];
    glGetProgramInfoLog(_program, sizeof(log), &logLen, log);
    NSLog(@"%s", log);
  }
  
  glUseProgram(_program);
  glValidateProgram(_program);
  glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &logLen);
  if (logLen > 0) {
    char log[2048];
    glGetProgramInfoLog(_program, sizeof(log), &logLen, log);
    NSLog(@"%s", log);
  }
  GLint sampler0 = glGetUniformLocation(_program, "sampler0");
  assert(sampler0 >= 0);
  glUniform1i(sampler0, 0);
  GLint sampler1 = glGetUniformLocation(_program, "sampler1");
  assert(sampler1 >= 0);
  glUniform1i(sampler1, 1);
  GLint sampler2 = glGetUniformLocation(_program, "sampler2");
  assert(sampler2 >= 0);
  glUniform1i(sampler2, 2);
  
  [self reshape];
}

- (BOOL)canDrawInOpenGLContext:(NSOpenGLContext *)context
                   pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
                  forLayerTime:(CFTimeInterval)lt displayTime:(const CVTimeStamp *)ts
{
  double t = [_decoder masterClock];
  return [_decoder.videoBuf time:_current] <= t;
}

- (void)drawInOpenGLContext:(NSOpenGLContext *)context
                pixelFormat:(NSOpenGLPixelFormat *)pixelFormat
               forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts;
{
  @autoreleasepool {
    if (!_init) {
      [self initGL:[self openGLContext]];
      _init = YES;
    }
    [self load:_current];
    [self draw:_current];
    [_decoder displaySubtitle];
    [_decoder decodeVideoBuffer:_current + ADVANCE];
    _current++;
  }
}

- (void) load:(int)i
{
  int width = _decoder.videoBuf.width;
  int height = _decoder.videoBuf.height;
  
  loadTexture(texIds[0][0], width, height, [_decoder.videoBuf dataY:i], [_decoder.videoBuf strideY:i]);
  loadTexture(texIds[0][1], width/2, height/2, [_decoder.videoBuf dataU:i], [_decoder.videoBuf strideU:i]);
  loadTexture(texIds[0][2], width/2, height/2, [_decoder.videoBuf dataV:i], [_decoder.videoBuf strideV:i]);
  
  if (0) {
    // Bind the rectange texture
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texIds[i % TEXTURE_COUNT][0]);
    glTexParameterf(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_PRIORITY, 1.0 );
    
    // Set a CACHED or SHARED storage hint for requesting VRAM or AGP texturing respectively
    // GL_STORAGE_PRIVATE_APPLE is the default and specifies normal texturing path
    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_CACHED_APPLE);
    
    // Eliminate a data copy by the OpenGL framework using the Apple client storage extension
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
  }
}

- (void) draw:(int)i
{
//  const GLfloat vertices[] = {
//    _movieRect.origin.x, _movieRect.origin.y,
//    _movieRect.origin.x, _movieRect.origin.y + _movieRect.size.height,
//    _movieRect.origin.x + _movieRect.size.width, _movieRect.origin.y + _movieRect.size.height,
//    _movieRect.origin.x + _movieRect.size.width, _movieRect.origin.y
//  };
  
//  GLfloat w = _decoder.videoBuf.width;
//  GLfloat h = _decoder.videoBuf.height;
  // Rectangle textures require non-normalized texture coordinates
//  const GLfloat texcoords[] = { 0, h, 0, 0, w, 0, w, h };
  
  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
//
////  glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texIds[i % TEXTURE_COUNT][0]);
////  glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
//  
//  glVertexPointer(2, GL_FLOAT, 0, vertices);
//  glDrawArrays(GL_QUADS, 0, 4);
  //draw RECT
//  glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, 0, 0, vertices);
  
  //ATTRIB_TEXTUREPOSITON
//  glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureCoords);
  
  glUseProgram(_program);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, texIds[0][0]);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, texIds[0][1]);
  glActiveTexture(GL_TEXTURE2);
  glBindTexture(GL_TEXTURE_2D, texIds[0][2]);
  glDrawArrays(GL_QUADS, 0, 4);
}

- (BOOL)frameChanged
{
  NSOpenGLContext* context = self.openGLContext;
  if (context) {
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
//	glViewport(0, 0, rect.size.width, rect.size.height);
	
  glUseProgram(_program);
  GLint ortho = glGetUniformLocation(_program, "Ortho");
  assert(ortho >= 0);
  GLfloat orthoMat[16];
  makeOrtho(vw, vh, orthoMat);
  glUniformMatrix4fv(ortho, 1, NO, orthoMat);
//	glMatrixMode(GL_PROJECTION);
//  glLoadIdentity();
//  glOrtho(0, rect.size.width, 0, rect.size.height, -1.0f, 1.0f);
//	glMatrixMode(GL_MODELVIEW);
	
  [self calcRect];
  
  GLfloat x0 = _movieRect.origin.x;
  GLfloat y0 = _movieRect.origin.y;
  GLfloat w = _decoder.videoBuf.width;
  GLfloat h = _decoder.videoBuf.height;
  GLfloat vertices[16] = {
    x0, y0,
    x0, y0 + _movieRect.size.height,
    x0 + _movieRect.size.width, y0 + _movieRect.size.height,
    x0 + _movieRect.size.width, y0,
//    0, h, 0, 0, w, 0, w, h
    0, 1, 0, 0, 1, 0, 1, 1
  };
  glBindBuffer(GL_ARRAY_BUFFER, _buffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
//  glEnableClientState(GL_VERTEX_ARRAY);
//  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
//  GLfloat* data = (GLfloat*)glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
//  memcpy(data, vertices, sizeof(vertices));
//  glUnmapBuffer(GL_ARRAY_BUFFER);
  
  GLint position = glGetAttribLocation(_program, "Position");
  assert(position >= 0);
  glVertexAttribPointer(position, 2, GL_FLOAT, GL_FALSE, 0, 0);
  glEnableVertexAttribArray(position);
  
  GLint texcoord = glGetAttribLocation(_program, "TexCoordIn");
  assert(texcoord >= 0);
  glVertexAttribPointer(texcoord, 2, GL_FLOAT, GL_FALSE, 0, (char*)0 + 8 * sizeof(GLfloat));
  glEnableVertexAttribArray(texcoord);
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
  for (int i = 0; i < ADVANCE; ++i) {
    [_decoder decodeVideoBuffer:_current + i];
  }
  self.asynchronous = YES;
}

@end
