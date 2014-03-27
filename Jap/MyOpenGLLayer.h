//
//  MyOpenGLLayer.h
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "Decoder.h"

@interface MyOpenGLLayer : NSOpenGLLayer
{
	GLuint texIds[TEXTURE_COUNT][3];
  int _current;
  GLuint _vertexShader;
  GLuint _fragmentShader;
  GLuint _program;
  GLuint _buffer;
  NSString* _path;
  CIContext* _ciContext;
  CVOpenGLTextureCacheRef _textureCache;
  BOOL _init;
}

@property (readonly) Decoder* decoder;
@property (readonly) CGRect movieRect;

- (void)open:(NSString*)path;
- (BOOL)frameChanged;

@end
