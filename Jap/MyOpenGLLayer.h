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
  GLfloat _x1, _y1, _x2, _y2; // coordinates to draw video
}

@end
