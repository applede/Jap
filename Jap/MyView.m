//
//  MyView.m
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "MyView.h"
#import "MyOpenGLLayer.h"

CALayer* setBlurFilters(CALayer* layer)
{
  layer.masksToBounds = YES;
  layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.6 alpha:0.7] CGColor];
  layer.needsDisplayOnBoundsChange = YES;
  CIFilter* saturationFilter = [CIFilter filterWithName:@"CIColorControls"];
  [saturationFilter setDefaults];
  [saturationFilter setValue:@2.0 forKey:@"inputSaturation"];
  CIFilter* clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
  [clampFilter setDefaults];
  [clampFilter setValue:[NSValue valueWithBytes:&CGAffineTransformIdentity objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
  CIFilter* blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
  [blurFilter setDefaults];
  [blurFilter setValue:@20.0 forKey:@"inputRadius"];
  layer.backgroundFilters = @[saturationFilter, clampFilter, blurFilter];
  [layer setNeedsDisplay];
  return layer;
}

@implementation MyView

- (id)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code here.
    [self setWantsBestResolutionOpenGLSurface:YES];
    _glLayer = [MyOpenGLLayer layer];
    [self setLayer:_glLayer];
    [self setWantsLayer:YES];
    [self setLayerUsesCoreImageFilters:YES];
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
    [self makeSublayers];
    _handler = self;
  }
  return self;
}

- (void)viewDidChangeBackingProperties
{
  CGFloat f = [self.window backingScaleFactor];
  _subtitle.contentsScale = f;
  [_mediaControl setContentsScale:f];
  [super viewDidChangeBackingProperties];
}

- (void)makeSublayers
{
  _subtitle = [CATextLayer layer];
  _subtitle.delegate = self;
  _subtitle.alignmentMode = kCAAlignmentCenter;
  _subtitle.font = (__bridge CFTypeRef)@"HelveticaNeue-Light";
  _subtitle.shadowOpacity = 1.0;
  _subtitle.shadowOffset = CGSizeMake(0.0, -1.0);

  _mediaControl = (MediaControlLayer*)setBlurFilters([MediaControlLayer layer]);
  _mediaControl.view = self;
  _mediaControl.anchorPoint = CGPointMake(0, 0);


  self.layer.layoutManager = [CAConstraintLayoutManager layoutManager];
  [self.layer addSublayer:_subtitle];
  [self.layer addSublayer:_mediaControl];
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
  return (id<CAAction>)[NSNull null];
}

- (void)frameChanged
{
  if ([_glLayer frameChanged]) {
    CGFloat s = _glLayer.contentsScale;
    CGFloat h = _glLayer.movieRect.size.height / s;
    CGFloat y = _glLayer.movieRect.origin.y / s;
    
    CGFloat fontSize = h * 0.08;
    _subtitleFont = [NSFont fontWithName:@"Apple SD Gothic Neo Medium"
                                    size:fontSize];
    if (!_subtitleFont) {
      _subtitleFont = [NSFont fontWithName:@"Helvetica Neue Medium"
                                      size:fontSize];
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [_subtitle setConstraints:@[[CAConstraint constraintWithAttribute:kCAConstraintMidX
                                                  relativeTo:@"superlayer"
                                                   attribute:kCAConstraintMidX],
                            [CAConstraint constraintWithAttribute:kCAConstraintMinY
                                                    relativeTo:@"superlayer"
                                                     attribute:kCAConstraintMinY offset:y]]];
    CGFloat mh = self.bounds.size.height * 128.0 / 1080.0;
    _mediaControl.bounds = CGRectMake(0, 0, self.bounds.size.width, mh);
    if (_handler == _mediaControl) {
      _mediaControl.position = CGPointMake(0, 0);
    } else {
      _mediaControl.position = CGPointMake(0, -mh);
    }
    [self.layer setNeedsLayout];
    
    [CATransaction commit];
  }
}

- (void)open:(NSString *)path
{
  _glLayer.subtitleDelegate = self;
  [_glLayer open:path];
  [self frameChanged];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
  _resizing = YES;
  _subtitle.string = @"";
  return frameSize;
}

- (void)windowDidResize:(NSNotification*)notification
{
  _resizing = NO;
  [self frameChanged];
}

- (void)displaySubtitle
{
  if (_resizing) {
    return;
  }
  NSString* newString = [_glLayer.decoder subtitleString];
  if (newString) {
    NSDictionary* attrs = @{NSFontAttributeName:_subtitleFont,
                            NSForegroundColorAttributeName:[NSColor whiteColor],
                            NSStrokeWidthAttributeName:@(-1.0),
                            NSStrokeColorAttributeName:[NSColor blackColor]
                            };
    NSAttributedString* str = [[NSAttributedString alloc] initWithString:newString
                                                              attributes:attrs];
    
    _subtitle.string = str;
  }
}

- (void)keyDown:(NSEvent *)theEvent
{
  NSString* chars = [theEvent charactersIgnoringModifiers];
  switch ([chars characterAtIndex:0]) {
    case 'm':
      [_handler menuPressed];
      break;
    case '\r':
      [_handler enterPressed];
      break;
    case ' ':
      [self spacePressed];
      break;
    case NSLeftArrowFunctionKey:
      [_handler leftPressed];
      break;
    case NSRightArrowFunctionKey:
      [_handler rightPressed];
      break;
    case 27:
      [_handler escPressed];
      break;
    default:
      break;
  }
}

- (void)menuPressed
{
  [self.layer addSublayer:_mediaControl];
  _mediaControl.position = CGPointMake(0, 0);
  _handler = _mediaControl;
}

- (void)enterPressed
{
  [[self window] toggleFullScreen:self];
}

- (void)escPressed
{
  [[self window] toggleFullScreen:self];
}

- (void)spacePressed
{
  if ([_glLayer.decoder isPlaying]) {
    [_glLayer.decoder pause];
  } else {
    [_glLayer.decoder play];
  }
}
- (void)leftPressed
{
  [_glLayer.decoder seek:-10.0];
}

- (void)rightPressed
{
  [_glLayer.decoder seek:10.0];
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

- (void)takeFocus
{
  _handler = self;
}

- (void)pause
{
  [_glLayer.decoder pause];
}

- (void)play
{
  [_glLayer.decoder play];
}

@end
