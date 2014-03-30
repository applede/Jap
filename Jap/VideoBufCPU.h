//
//  VideoBufCPU.h
//  Jap
//
//  Created by Jake Song on 3/28/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoBuf.h"

@interface VideoBufCPU : VideoBuf
{
  double _time[TEXTURE_COUNT];
	GLuint _texIds[TEXTURE_COUNT][3];
  AVFrame* _frame[TEXTURE_COUNT];
  int _frameSize;
  struct SwsContext *_imgConvertCtx;
  
  int _count;
  int _front;
  int _back;
  NSLock* _lock;
  
  int _size;
  GLubyte* _data;
}

- initDecoder:(Decoder*)decoder stream:(AVStream*)stream;

- (GLubyte*)dataY:(int)i;
- (GLubyte*)dataU:(int)i;
- (GLubyte*)dataV:(int)i;
- (int)strideY:(int)i;
- (int)strideU:(int)i;
- (int)strideV:(int)i;

@end
