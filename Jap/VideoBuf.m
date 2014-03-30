//
//  VideoQueue.m
//  Jap
//
//  Created by Jake Song on 3/17/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <libswscale/swscale.h>
#import "VideoBuf.h"
#import "Decoder.h"

@implementation VideoBuf

- (GLuint)program
{
  return program_;
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

- (void)compileVertex:(const char*)vertexSrc fragment:(const char*)fragmentSrc
{
  GLuint vertexShader = compileShader(GL_VERTEX_SHADER, vertexSrc);
  GLuint fragmentShader = compileShader(GL_FRAGMENT_SHADER, fragmentSrc);
  
  program_ = glCreateProgram();
  glAttachShader(program_, vertexShader);
  glAttachShader(program_, fragmentShader);
  glLinkProgram(program_);
  int logLen;
  glGetProgramiv(program_, GL_INFO_LOG_LENGTH, &logLen);
  if (logLen > 0) {
    char log[2048];
    glGetProgramInfoLog(program_, sizeof(log), &logLen, log);
    NSLog(@"%s", log);
  }
}

- (int)width
{
  return width_;
}

- (int)height
{
  return height_;
}

- (void)prepare:(CGLContextObj)cgl
{
}

- (double)time:(int)i
{
  return time_[mod(i)];
}

- (void)setTime:(double)t of:(int)i
{
  time_[mod(i)] = t;
}

- (void)decode:(int)i
{
}

- (void)load:(int)i
{
}

- (void)draw:(int)i
{
}

@end