//
//  VideoBufVDA.h
//  Jap
//
//  Created by Jake Song on 3/28/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoDecodeAcceleration/VDADecoder.h>
#import "VideoBuf.h"

@interface VideoBufGPU : VideoBuf
{
  VDADecoder vda_decoder_;
  CGLContextObj cgl_ctx_;
  CVPixelBufferRef image_[TEXTURE_COUNT];
  IOSurfaceRef surface_[TEXTURE_COUNT];
  GLuint texIds_[TEXTURE_COUNT];
}

- initDecoder:(Decoder*)decoder stream:(AVStream *)stream;
- (void)onFrameReady:(CVImageBufferRef)image time:(double)time index:(int)i;

@end
