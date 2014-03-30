//
//  VideoBufVDA.m
//  Jap
//
//  Created by Jake Song on 3/28/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "VideoBufGPU.h"
#import "Decoder.h"

NSString* const kDisplayTimeKey = @"display_time";
NSString* const kIndexKey = @"index";

static void OnFrameReadyCallback(void *callback_data,
                                 CFDictionaryRef frame_info,
                                 OSStatus status,
                                 uint32_t flags,
                                 CVImageBufferRef image_buffer) {
  @autoreleasepool {
    assert(status == 0);
    assert(image_buffer);
    assert(CVPixelBufferGetPixelFormatType(image_buffer) == '2vuy');
//    CGSize size = CVImageBufferGetDisplaySize(image_buffer);
    NSDictionary* info = (__bridge NSDictionary*)frame_info;
    VideoBufGPU* videoBuf = (__bridge VideoBufGPU*)callback_data;
    [videoBuf onFrameReady:image_buffer time:[info[kDisplayTimeKey] doubleValue]
                     index:[info[kIndexKey] intValue]];
  }
}

@implementation VideoBufGPU

- (id)initDecoder:(Decoder *)decoder stream:(AVStream *)stream
{
  self = [super init];
  if (self) {
    decoder_ = decoder;
    stream_ = stream;
    AVCodecContext* context = stream->codec;
    width_ = context->width;
    height_ = context->height;
    int sourceFormat = 'avc1';
    NSDictionary* config = @{(id)kVDADecoderConfiguration_Width:@(width_),
                             (id)kVDADecoderConfiguration_Height:@(height_),
                             (id)kVDADecoderConfiguration_SourceFormat:@(sourceFormat),
                             (id)kVDADecoderConfiguration_avcCData:[NSData dataWithBytes:context->extradata
                                                                                  length:context->extradata_size]};
//    NSMutableDictionary* config = [NSMutableDictionary dictionary];
//    [config setObject:[NSNumber numberWithInt:width]
//               forKey:(NSString*)kVDADecoderConfiguration_Width];
//    [config setObject:[NSNumber numberWithInt:height]
//               forKey:(NSString*)kVDADecoderConfiguration_Height];
//    [config setObject:[NSNumber numberWithInt:source_format]
//               forKey:(NSString*)kVDADecoderConfiguration_SourceFormat];
    assert(context->extradata);
//    NSData* avc_data = [NSData dataWithBytes:avc_bytes length:avc_size];
//    [config setObject:avc_data
//               forKey:(NSString*)kVDADecoderConfiguration_avcCData];

//    NSMutableDictionary* format_info = [NSMutableDictionary dictionary];
//    // This format is used by the CGLTexImageIOSurface2D call in IOSurfaceTestView.
//    [format_info setObject:[NSNumber numberWithInt:kCVPixelFormatType_422YpCbCr8]
//                    forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
//    [format_info setObject:[NSDictionary dictionary]
//                    forKey:(NSString*)kCVPixelBufferIOSurfacePropertiesKey];
    NSDictionary* formatInfo = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_422YpCbCr8),
                                 (id)kCVPixelBufferIOSurfacePropertiesKey: @{}};

    OSStatus status = VDADecoderCreate((__bridge CFDictionaryRef)config,
                                       (__bridge CFDictionaryRef)formatInfo, // optional
                                       (VDADecoderOutputCallback*)OnFrameReadyCallback,
                                       (__bridge void*)self,
                                       &vda_decoder_);
    if (status == kVDADecoderHardwareNotSupportedErr)
      fprintf(stderr, "hadware does not support GPU decoding\n");
    assert(status == kVDADecoderNoErr);
  }
  return self;
}

- (void)dealloc
{
  VDADecoderDestroy(vda_decoder_);
}

- (void)onFrameReady:(CVPixelBufferRef)image time:(double)time index:(int)i
{
  NSLog(@"frame ready %.3f %d", time, i);
  if (image_[mod(i)]) {
    CFRelease(image_[mod(i)]);
  }
  image_[mod(i)] = CVBufferRetain(image);
  IOSurfaceRef io_surface = CVPixelBufferGetIOSurface(image);
  // _bindSurfaceToTexture assumes that the surface is retained.
  CFRetain(io_surface);
  [self _bindSurfaceToTexture:io_surface to:i];
  [self setTime:time of:i];
}

- (void)_bindSurfaceToTexture:(IOSurfaceRef)aSurface to:(int)index
{
  int i = mod(index);
	if (surface_[i] && (surface_[i] != aSurface)) {
		CFRelease(surface_[i]);
	}
	surface_[i] = aSurface;
}

- (void)prepare:(CGLContextObj)cgl
{
  cgl_ctx_ = cgl;
  glEnable(GL_TEXTURE_RECTANGLE_ARB);
  for (int i = 0; i < TEXTURE_COUNT; i++) {
    assert(texIds_[i] == 0);
    glGenTextures(1, &texIds_[i]);
  }
#if 1
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
   "uniform sampler2DRect sampler0;"
   "varying vec2 TexCoordOut;"
   "void main(void)"
   "{"
   "  gl_FragColor = texture2DRect(sampler0, TexCoordOut);"
   "}"];
  glUseProgram(program_);
  GLint sampler0 = glGetUniformLocation(program_, "sampler0");
  assert(sampler0 >= 0);
  glUniform1i(sampler0, 0);
  
  GLint position = glGetAttribLocation(program_, "Position");
  assert(position >= 0);
  glVertexAttribPointer(position, 2, GL_FLOAT, GL_FALSE, 0, 0);
  glEnableVertexAttribArray(position);
  
  GLint texcoord = glGetAttribLocation(program_, "TexCoordIn");
  assert(texcoord >= 0);
  glVertexAttribPointer(texcoord, 2, GL_FLOAT, GL_FALSE, 0, (char*)0 + 8 * sizeof(GLfloat));
  glEnableVertexAttribArray(texcoord);
#endif
}

- (void)decode:(int)i
{
  AVPacket pkt = { 0 };
  AVRational tb = stream_->time_base;
  
  if (!quit_ && ![decoder_.videoQue isEmpty]) {
    [decoder_.videoQue get:&pkt];
    assert(pkt.data);
    NSLog(@"i %d", i);
    
    NSData* data = [NSData dataWithBytes:pkt.data length:pkt.size];
    double pts = pkt.pts * av_q2d(tb);
    NSDictionary* frame_info = @{kDisplayTimeKey:@(pts),
                                 kIndexKey:@(i)};
    OSStatus r = VDADecoderDecode(vda_decoder_, 0, (__bridge CFDataRef)data,
                                  (__bridge CFDictionaryRef)frame_info);
    assert(r == 0);
    av_free_packet(&pkt);
  }
  [decoder_ checkQueue];
}

- (void)load:(int)index
{
  NSLog(@"load");
  int i = mod(index);
  assert(surface_[i]);
  GLsizei	width	= (GLsizei)IOSurfaceGetWidth(surface_[i]);
  GLsizei	height = (GLsizei)IOSurfaceGetHeight(surface_[i]);
	
  glEnable(GL_TEXTURE_RECTANGLE_ARB);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texIds_[i]);
  CGLTexImageIOSurface2D(cgl_ctx_, GL_TEXTURE_RECTANGLE_ARB, GL_RGB8,
                         width, height,
                         GL_YCBCR_422_APPLE, GL_UNSIGNED_SHORT_8_8_APPLE, surface_[i], 0);
  //		CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE_ARB, GL_RGBA8,
  //							   _texWidth, _texHeight,
  //							   GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, _surface, 0);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
  glDisable(GL_TEXTURE_RECTANGLE_ARB);
  
  glFlush();
}

- (void)draw:(int)i
{
  NSLog(@"draw");
#if 1
  glUseProgram(program_);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texIds_[mod(i)]);
  glDrawArrays(GL_QUADS, 0, 4);
#else
  glEnable(GL_TEXTURE_RECTANGLE_ARB);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texIds_[mod(i)]);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glBegin(GL_QUADS);
		glTexCoord2f(0.0, 0.0);
		glVertex3f(-1.0, -1.0, 0.0);
		glTexCoord2f(width_, 0.0);
		glVertex3f(1.0, -1.0, 0.0);
		glTexCoord2f(width_, height_);
		glVertex3f(1.0, 1.0, 0.0);
		glTexCoord2f(0.0, height_);
		glVertex3f(-1.0, 1.0, 0.0);
	glEnd();
#endif
}

@end
