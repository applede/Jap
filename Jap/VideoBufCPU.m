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
  self = [super init];
  if (self) {
    decoder_ = decoder;
    stream_ = stream;
    width_ = TEXTURE_WIDTH;
    height_ = TEXTURE_HEIGHT;
    AVCodecContext *context = stream->codec;
    AVCodec *codec = avcodec_find_decoder(context->codec_id);
    if (avcodec_open2(context, codec, NULL) < 0) {
      NSLog(@"avcodec_open2");
    }
    frameSize_ = avpicture_get_size(AV_PIX_FMT_YUV420P, width_, height_);
    _size = frameSize_ * TEXTURE_COUNT;
    _data = calloc(TEXTURE_COUNT, frameSize_);
    for (int i = 0; i < TEXTURE_COUNT; i++) {
      time_[i] = DBL_MAX;
      frame_[i] = av_frame_alloc();
      avpicture_fill((AVPicture*)frame_[i], &_data[frameSize_ * i], AV_PIX_FMT_YUV420P, width_, height_);
    }
  }
  return self;
}

- (void)dealloc
{
  for (int i = 0; i < TEXTURE_COUNT; i++) {
    av_frame_free(&frame_[i]);
  }
  free(_data);
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
    assert(texIds_[i][0] == 0);
    texIds_[i][0] = createTexture(GL_TEXTURE0, width_, height_, [self dataY:i]);
    
    //: U Texture
    assert(texIds_[i][1] == 0);
    texIds_[i][1] = createTexture(GL_TEXTURE1, width_ / 2, height_ / 2, [self dataU:i]);
    
    //: V Texture
    assert(texIds_[i][2] == 0);
    texIds_[i][2] = createTexture(GL_TEXTURE2, width_ / 2, height_ / 2, [self dataV:i]);
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
  
  glUseProgram(program_);
  
  GLint sampler0 = glGetUniformLocation(program_, "sampler0");
  assert(sampler0 >= 0);
  glUniform1i(sampler0, 0);
  GLint sampler1 = glGetUniformLocation(program_, "sampler1");
  assert(sampler1 >= 0);
  glUniform1i(sampler1, 1);
  GLint sampler2 = glGetUniformLocation(program_, "sampler2");
  assert(sampler2 >= 0);
  glUniform1i(sampler2, 2);
  
  GLint position = glGetAttribLocation(program_, "Position");
  assert(position >= 0);
  glVertexAttribPointer(position, 2, GL_FLOAT, GL_FALSE, 0, 0);
  glEnableVertexAttribArray(position);
  
  GLint texcoord = glGetAttribLocation(program_, "TexCoordIn");
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

- (void)loadTexture:(int)i
{
  loadTexture(texIds_[mod(i)][0], width_, height_, [self dataY:i], [self strideY:i]);
  loadTexture(texIds_[mod(i)][1], width_/2, height_/2, [self dataU:i], [self strideU:i]);
  loadTexture(texIds_[mod(i)][2], width_/2, height_/2, [self dataV:i], [self strideV:i]);
}

- (void)draw:(int)i
{
  glUseProgram(program_);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, texIds_[mod(i)][0]);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, texIds_[mod(i)][1]);
  glActiveTexture(GL_TEXTURE2);
  glBindTexture(GL_TEXTURE_2D, texIds_[mod(i)][2]);
  glDrawArrays(GL_QUADS, 0, 4);
}

- (void)setDecoder:(Decoder *)decoder stream:(AVStream *)stream
{
}

- (GLubyte *)dataY:(int)i
{
  return frame_[mod(i)]->data[0];
}

- (GLubyte *)dataU:(int)i
{
  return frame_[mod(i)]->data[1];
}

- (GLubyte *)dataV:(int)i
{
  return frame_[mod(i)]->data[2];
}

- (int)strideY:(int)i
{
  return frame_[mod(i)]->linesize[0];
}

- (int)strideU:(int)i
{
  return frame_[mod(i)]->linesize[1];
}

- (int)strideV:(int)i
{
  return frame_[mod(i)]->linesize[2];
}

- (void)decode:(int)i
{
  AVPacket pkt = { 0 };
  AVFrame *frame = frame_[mod(i)];
  double pts;
  AVRational tb = stream_->time_base;
  
  while (!quit_ && ![decoder_.videoQue isEmpty]) {
    if ([self getVideoFrame:frame packet:&pkt]) {
      pts = (frame->pts == AV_NOPTS_VALUE) ? NAN : frame->pts * av_q2d(tb);
      [self putTime:pts pos:av_frame_get_pkt_pos(frame) into:i];
//      av_frame_unref(frame);
      break;
    }
    av_free_packet(&pkt);
  }
  [decoder_ checkQueue];

  av_free_packet(&pkt);
}

- (BOOL)getVideoFrame:(AVFrame*)frame packet:(AVPacket*)pkt
{
  [decoder_.videoQue get:pkt];
  int got_picture = NO;
  if (avcodec_decode_video2(stream_->codec, frame, &got_picture, pkt) < 0) {
    NSLog(@"avcodec_decode_video2");
    return NO;
  }
  if (got_picture) {
    double dpts = NAN;
    
    frame->pts = av_frame_get_best_effort_timestamp(frame);
    
    if (frame->pts != AV_NOPTS_VALUE)
      dpts = av_q2d(stream_->time_base) * frame->pts;
    
    return YES;
  }
  return NO;
}

- (void)putTime:(double)t pos:(int64_t)p into:(int)i
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
  [self setTime:t of:i];
  //  NSLog(@"decoded %d", i);
}

@end
