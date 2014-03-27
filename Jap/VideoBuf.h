//
//  VideoQueue.h
//  Jap
//
//  Created by Jake Song on 3/17/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

@class Decoder;

#define TEXTURE_COUNT		5

@interface VideoBuf : NSObject
{
  BOOL _quit;
  Decoder* _decoder;
  AVStream* _stream;
  
  struct SwsContext *_img_convert_ctx;
  double _time[TEXTURE_COUNT];
  CVPixelBufferRef _pixelBuf[TEXTURE_COUNT];
  AVFrame* _frame[TEXTURE_COUNT];
  GLubyte* _data;
}

@property int size;
@property int width;
@property int height;

- (void)setDecoder:(Decoder*)decoder stream:(AVStream*)stream;

- (double)time:(int)i;
- (void)setTime:(double)t of:(int)i;
- (GLubyte*)data:(int)i;
- (GLubyte*)dataY:(int)i;
- (GLubyte*)dataU:(int)i;
- (GLubyte*)dataV:(int)i;
- (int)strideY:(int)i;
- (int)strideU:(int)i;
- (int)strideV:(int)i;

- (void)decode:(int)i;

@end
