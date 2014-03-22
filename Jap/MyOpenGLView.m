#import "MyOpenGLView.h"
#import <OpenGL/glu.h>

@implementation MyOpenGLView

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
	// There is no autorelease pool when this method is called because it will be called from a background thread
	// It's important to create one or you will leak objects
  @autoreleasepool {
    double t = [_decoder masterClock];
    while ([_decoder.videoBuf time:_current + 1] <= t) {
      [_decoder decodeVideoBuffer:_toDecode++];
      _current++;
    }
    if ([_decoder.videoBuf time:_current] <= t) {
      [self load:_current];
      [self draw:_current];
      [_decoder decodeVideoBuffer:_toDecode++];
      _current++;
    }
  }
	
  return kCVReturnSuccess;
}

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    CVReturn result = [(__bridge MyOpenGLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (id) initWithFrame:(NSRect)frameRect
{
  NSOpenGLPixelFormatAttribute attrs[] = {
		NSOpenGLPFAAccelerated,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 0,
		0
  };
	
  NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
	
  if (!pf)
		NSLog(@"No OpenGL pixel format");
	
  if (self = [super initWithFrame:frameRect pixelFormat:pf]) {
    [self  setWantsBestResolutionOpenGLSurface:YES];
    _decoder = [[Decoder alloc] init];
		[self initGL];
		
		// Create a display link capable of being used with all active displays
		CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
		
		// Set the renderer output callback function
		CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void*)self);
		
		// Set the display link for the current renderer
		CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
		CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
		CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
		
    [_decoder start];
    for (_toDecode = 0; _toDecode < TEXTURE_COUNT - 1;) {
      [_decoder decodeVideoBuffer:_toDecode++];
    }
    [self calcRect];
		// Activate the display link
		CVDisplayLinkStart(displayLink);
    _startTime = CVGetCurrentHostTime();
    _freq = CVGetHostClockFrequency();
	}
	
	return self;
}
	
- (void) initGL
{
	[[self openGLContext] makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; 
	
	// Create OpenGL textures
  [self initTextures];
	
	glDisable(GL_DEPTH_TEST);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
}

- (void) load:(int)i
{
	CGLLockContext([[self openGLContext] CGLContextObj]);
	[[self openGLContext] makeCurrentContext];
	// Enable the rectangle texture extenstion
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
//	glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, _buffer.size, [_buffer frontData]);
	
  // Bind the rectange texture
  glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texIds[i]);
  
  // Set a CACHED or SHARED storage hint for requesting VRAM or AGP texturing respectively
  // GL_STORAGE_PRIVATE_APPLE is the default and specifies normal texturing path
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_CACHED_APPLE);
  
  // Eliminate a data copy by the OpenGL framework using the Apple client storage extension
  glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
		
  // Rectangle textures has its limitations compared to using POT textures, for example,
  // Rectangle textures can't use mipmap filtering
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		
  // Rectangle textures can't use the GL_REPEAT warp mode
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
			
  glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
			
  // OpenGL likes the GL_BGRA + GL_UNSIGNED_INT_8_8_8_8_REV combination
  glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA,
               _decoder.videoBuf.width, _decoder.videoBuf.height, 0,
               GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, [_decoder.videoBuf data:i]);
	
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void) initTextures
{
	glGenTextures(TEXTURE_COUNT, texIds);
	
	// Enable the rectangle texture extenstion
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	
	// Eliminate a data copy by the OpenGL driver using the Apple texture range extension along with the rectangle texture extension
	// This specifies an area of memory to be mapped for all the textures. It is useful for tiled or multiple textures in contiguous memory.
	glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, _decoder.videoBuf.size, [_decoder.videoBuf data:0]);
}

- (void) reshape
{
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main thread
	// Add a mutex around to avoid the threads accessing the context simultaneously when resizing
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
  NSRect rect = [self convertRectToBacking:[self bounds]];
	glViewport(0, 0, rect.size.width, rect.size.height);
	
	glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(0, rect.size.width, 0, rect.size.height, -10.0f, 10.0f);
	glMatrixMode(GL_MODELVIEW);
	
  [self calcRect];
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)calcRect
{
  NSRect bounds = [self convertRectToBacking:[self bounds]];
  
  int srcW = _decoder.videoBuf.width;
  int srcH = _decoder.videoBuf.height;
  GLfloat viewW = bounds.size.width;
  GLfloat viewH = bounds.size.height;

  GLfloat dstW = viewH * srcW / srcH;
  GLfloat dstH;

  if (dstW <= viewW) {
    dstH = viewH;
  } else {
    dstH = viewW * srcH / srcW;
    dstW = viewW;
  }
  
  _x1 = (viewW - dstW) / 2;
  _y1 = (viewH - dstH) / 2;
  _x2 = _x1 + dstW;
  _y2 = _y1 + dstH;
}

- (void) draw:(int)i
{
	const GLfloat vertices[] = { _x1, _y1, _x1, _y2, _x2, _y2, _x2, _y1 };
	
  GLfloat w = _decoder.videoBuf.width;
  GLfloat h = _decoder.videoBuf.height;
	// Rectangle textures require non-normalized texture coordinates
	const GLfloat texcoords[] = { 0, h, 0, 0, w, 0, w, h };
	
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main thread
	// Add a mutex around to avoid the threads accessing the context simultaneously	when resizing
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	[[self openGLContext] makeCurrentContext];
	
//	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
//	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
  glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texIds[i]);
		
  glVertexPointer(2, GL_FLOAT, 0, vertices);
  glDrawArrays(GL_QUADS, 0, 4);
	
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
	
	[[self openGLContext] flushBuffer];
	
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void) dealloc
{
	glDeleteTextures(TEXTURE_COUNT, texIds);
	
	// Release the display link
  CVDisplayLinkRelease(displayLink);
}

@end
