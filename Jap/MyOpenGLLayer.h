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
  int _current;
  GLuint buffer_;
  NSString* _path;
}

@property (readonly) Decoder* decoder;
@property (readonly) CGRect movieRect;

- (void)open:(NSString*)path;
- (BOOL)frameChanged;

@end
