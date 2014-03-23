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
  Decoder* _decoder;
	GLuint texIds[TEXTURE_COUNT];
  int _current;
  int _clear;
  NSString* _path;
}

@property (readonly) CGRect movieRect;

- (void)open:(NSString*)path;
- (void)frameChanged;

@end
