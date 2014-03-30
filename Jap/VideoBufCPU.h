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
	GLuint texIds_[TEXTURE_COUNT][3];
  AVFrame* frame_[TEXTURE_COUNT];
  int frameSize_;
  struct SwsContext *img_convert_ctx_;
}

@property (readonly) int size;
@property (readonly) GLubyte* data;

- initDecoder:(Decoder*)decoder stream:(AVStream*)stream;

- (GLubyte*)dataY:(int)i;
- (GLubyte*)dataU:(int)i;
- (GLubyte*)dataV:(int)i;
- (int)strideY:(int)i;
- (int)strideU:(int)i;
- (int)strideV:(int)i;

@end
