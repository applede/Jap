//
//  VideoBufCPU.m
//  Jap
//
//  Created by Jake Song on 3/28/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <OpenGL/gl.h>
#import "VideoBufCPU.h"
#import "Decoder.h"

#define TEXTURE_WIDTH		1920
#define TEXTURE_HEIGHT	1080

@implementation VideoBufCPU

- (id)initDecoder:(Decoder *)decoder stream:(AVStream *)stream
{
  self = [super initDecoder:decoder stream:stream];
  if (self) {
    AVCodecContext *context = stream->codec;
    AVCodec *codec = avcodec_find_decoder(context->codec_id);
    if (avcodec_open2(context, codec, NULL) < 0) {
      NSLog(@"avcodec_open2");
    }
    _frameSize = avpicture_get_size(AV_PIX_FMT_YUV420P, _width, _height);
    _size = _frameSize * TEXTURE_COUNT;
    _data = calloc(TEXTURE_COUNT, _frameSize);
    for (int i = 0; i < TEXTURE_COUNT; i++) {
      _frame[i] = av_frame_alloc();
      avpicture_fill((AVPicture*)_frame[i], &_data[_frameSize * i], AV_PIX_FMT_YUV420P, _width, _height);
    }
    _front = 0;
    _back = 0;
    _count = 0;
    _lock = [[NSLock alloc] init];
  }
  return self;
}

- (void)dealloc
{
  for (int i = 0; i < TEXTURE_COUNT; i++) {
    av_frame_free(&_frame[i]);
  }
  free(_data);
}

- (float)textureWidth
{
  return 1.0;
}

- (float)textureHeight
{
  return 1.0;
}

GLuint createTexture(GLenum unit, GLsizei width, GLsizei height, GLubyte* data)
{
  GLuint texture = 0;
  
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
  glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  // This is necessary for non-power-of-two textures
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  
  glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, width, height, 0, GL_RED, GL_UNSIGNED_BYTE, data);
  return texture;
}

- (void)prepare:(CGLContextObj)cgl
{
	// Eliminate a data copy by the OpenGL driver using the Apple texture range extension along with the rectangle texture extension
	// This specifies an area of memory to be mapped for all the textures. It is useful for tiled or multiple textures in contiguous memory.
	glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, _size, _data);
  glEnable(GL_UNPACK_CLIENT_STORAGE_APPLE);
  
  for (int i = 0; i < TEXTURE_COUNT; i++) {
    //: Y Texture
    assert(_texIds[i][0] == 0);
    _texIds[i][0] = createTexture(GL_TEXTURE0, _width, _height, [self dataY:i]);
    
    //: U Texture
    assert(_texIds[i][1] == 0);
    _texIds[i][1] = createTexture(GL_TEXTURE1, _width / 2, _height / 2, [self dataU:i]);
    
    //: V Texture
    assert(_texIds[i][2] == 0);
    _texIds[i][2] = createTexture(GL_TEXTURE2, _width / 2, _height / 2, [self dataV:i]);
  }

  [self compileVertex:
   "#version 120\n"
   "attribute vec2 Position;\n"
   "attribute vec2 TexCoordIn;\n"
   "varying vec2 TexCoordOut;\n"
   "uniform mat4 Ortho;\n"
   "void main()\n"
   "{\n"
   "  gl_Position = Ortho * vec4(Position, 0, 1);"
   "  TexCoordOut = TexCoordIn;"
   "}"
             fragment:
   "#version 120\n"
   "uniform sampler2D sampler0;"
   "uniform sampler2D sampler1;"
   "uniform sampler2D sampler2;"
   "varying vec2 TexCoordOut;"
   "void main(void)"
   "{"
   "  float y = texture2D(sampler0, TexCoordOut).r;"
   "  float u = texture2D(sampler1, TexCoordOut).r - 0.5;"
   "  float v = texture2D(sampler2, TexCoordOut).r - 0.5;"
   // sdtv (BT.601)
   //  "  float r = y + 1.13983 * v;"
   //  "  float g = y - 0.39465 * u - 0.58060 * v;"
   //  "  float b = y + 2.03211 * u;"
   // hdtv (BT.709)
   "  float r = y + 1.28033 * v;"
   "  float g = y - 0.21482 * u - 0.38059 * v;"
   "  float b = y + 2.12798 * u;"
   "  gl_FragColor = vec4(r, g, b, 1.0);"
   "}"];
  
  glUseProgram(_program);
  
  GLint sampler0 = glGetUniformLocation(_program, "sampler0");
  assert(sampler0 >= 0);
  glUniform1i(sampler0, 0);
  GLint sampler1 = glGetUniformLocation(_program, "sampler1");
  assert(sampler1 >= 0);
  glUniform1i(sampler1, 1);
  GLint sampler2 = glGetUniformLocation(_program, "sampler2");
  assert(sampler2 >= 0);
  glUniform1i(sampler2, 2);
  
  GLint position = glGetAttribLocation(_program, "Position");
  assert(position >= 0);
  glVertexAttribPointer(position, 2, GL_FLOAT, GL_FALSE, 0, 0);
  glEnableVertexAttribArray(position);
  
  GLint texcoord = glGetAttribLocation(_program, "TexCoordIn");
  assert(texcoord >= 0);
  glVertexAttribPointer(texcoord, 2, GL_FLOAT, GL_FALSE, 0, (char*)0 + 8 * sizeof(GLfloat));
  glEnableVertexAttribArray(texcoord);
  
}

void loadTexture(GLuint texture, GLsizei width, GLsizei height, GLubyte* data, int stride)
{
  glBindTexture(GL_TEXTURE_2D, texture);
  glPixelStorei(GL_UNPACK_ROW_LENGTH, stride);
  // glTexSubImage2D does memmove
  glTexImage2D(GL_TEXTURE_2D, 0, GL_R8, width, height, 0, GL_RED, GL_UNSIGNED_BYTE, data);
}

- (double)frontTime
{
  double t = DBL_MAX;
  [_lock lock];
  if (_count > 0) {
    t = _time[_front];
  }
  [_lock unlock];
  return t;
}

- (void)draw
{
  loadTexture(_texIds[_front][0], _width, _height, [self dataY:_front], [self strideY:_front]);
  loadTexture(_texIds[_front][1], _width/2, _height/2, [self dataU:_front], [self strideU:_front]);
  loadTexture(_texIds[_front][2], _width/2, _height/2, [self dataV:_front], [self strideV:_front]);
  
  glUseProgram(_program);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, _texIds[_front][0]);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, _texIds[_front][1]);
  glActiveTexture(GL_TEXTURE2);
  glBindTexture(GL_TEXTURE_2D, _texIds[_front][2]);
  glDrawArrays(GL_QUADS, 0, 4);
  
  [self remove];
  [self signal];
}

- (GLubyte *)dataY:(int)i
{
  return _frame[i]->data[0];
}

- (GLubyte *)dataU:(int)i
{
  return _frame[i]->data[1];
}

- (GLubyte *)dataV:(int)i
{
  return _frame[i]->data[2];
}

- (int)strideY:(int)i
{
  return _frame[i]->linesize[0];
}

- (int)strideU:(int)i
{
  return _frame[i]->linesize[1];
}

- (int)strideV:(int)i
{
  return _frame[i]->linesize[2];
}

- (BOOL)isFull
{
  return _count >= TEXTURE_COUNT;
}

- (void)remove
{
  [_lock lock];
  _front = (_front + 1) % TEXTURE_COUNT;
  _count--;
  [_lock unlock];
}

- (void)decodeLoop
{
  AVPacket pkt = { 0 };
  AVFrame *frame = _frame[_back];
  double pts;
  AVRational tb = _stream->time_base;
  
  while (!_quit && ![_decoder.videoQue isEmpty] && ![self isFull]) {
    if ([self getVideoFrame:frame packet:&pkt]) {
      pts = (frame->pts == AV_NOPTS_VALUE) ? NAN : frame->pts * av_q2d(tb);
      [self putTime:pts pos:av_frame_get_pkt_pos(frame)];
//      av_frame_unref(frame);
    }
    av_free_packet(&pkt);
  }
}

- (BOOL)getVideoFrame:(AVFrame*)frame packet:(AVPacket*)pkt
{
  [_decoder.videoQue get:pkt];
  int got_picture = NO;
  if (avcodec_decode_video2(_stream->codec, frame, &got_picture, pkt) < 0) {
    NSLog(@"avcodec_decode_video2");
    return NO;
  }
  if (got_picture) {
    double dpts = NAN;
    
    frame->pts = av_frame_get_best_effort_timestamp(frame);
    
    if (frame->pts != AV_NOPTS_VALUE)
      dpts = av_q2d(_stream->time_base) * frame->pts;
    
    return YES;
  }
  return NO;
}

- (void)putTime:(double)t pos:(int64_t)p
{
//    _img_convert_ctx = sws_getCachedContext(_img_convert_ctx,
//                                            frame->width, frame->height, frame->format,
//                                            _width, _height,
//                                            AV_PIX_FMT_BGRA, SWS_FAST_BILINEAR, NULL, NULL, NULL);
//    if (_img_convert_ctx == NULL) {
//      NSLog(@"Cannot initialize the conversion context");
//    }
//    GLubyte* data[] = { [self data:i] };
//    int linesize[] = { _width * 4 };
//    sws_scale(_img_convert_ctx, (const uint8_t* const*)frame->data, frame->linesize, 0, _height,
//              data, linesize);
  [_lock lock];
  _time[_back] = t;
  _back = (_back + 1) % TEXTURE_COUNT;
  _count++;
  [_lock unlock];
  //  NSLog(@"decoded %d", i);
}

@end
