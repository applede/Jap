#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>
#import "Decoder.h"

@interface MyOpenGLView : NSOpenGLView {
	GLuint texIds[TEXTURE_COUNT];
	CVDisplayLinkRef displayLink;
  int _current;
  int _toDecode;
  Decoder* _decoder;
  GLfloat _x1, _y1, _x2, _y2;
}

@end
