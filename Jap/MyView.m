//
//  MyView.m
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "MyView.h"
#import "MyOpenGLLayer.h"

#define OFF 0
#define ON  1

void resetFilters(CALayer* layer)
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
}

CALayer* makeBlurLayer()
{
  CALayer* layer = [CALayer layer];
  resetFilters(layer);
  return layer;
}

@implementation MyView

- (id)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code here.
    [self setWantsBestResolutionOpenGLSurface:YES];
    [self setLayer:[MyOpenGLLayer layer]];
    [self setWantsLayer:YES];
    [self setLayerUsesCoreImageFilters:YES];
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
    [self makeSublayers];
    _menuHidden = YES;
  }
  return self;
}

- (void)viewDidChangeBackingProperties
{
  CGFloat f = [self.window backingScaleFactor];
  _subtitle.contentsScale = f;
  _menu.contentsScale = f;
  for (int i = 0; i < BUTTON_COUNT; i++) {
    _buttons[i].contentsScale = f;
  }
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
//  _text.shadowRadius = 1.0;

  _menu = makeBlurLayer();
  _menu.anchorPoint = CGPointMake(0, 0);
  
  static NSString* imageNames[][2] = {
    {@"skip-to-start-128-black.png", @"skip-to-start-128-white.png"},
    {@"rewind-128-black.png", @"rewind-128-white.png"},
    {@"pause-128-black.png", @"pause-128-white.png"},
    {@"stop-128-black.png", @"stop-128-white.png"},
    {@"fast-forward-128-black.png", @"fast-forward-128-white.png"},
    {@"end-128-black.png", @"end-128-white.png"},
  };
  for (int i = 0; i < BUTTON_COUNT; i++) {
    _images[i][OFF] = [NSImage imageNamed:imageNames[i][OFF]];
    _images[i][ON] = [NSImage imageNamed:imageNames[i][ON]];
    
    _buttons[i] = [CALayer layer];
    _buttons[i].contents = _images[i][OFF];
    _buttons[i].anchorPoint = CGPointMake(0, 0);
    [_menu addSublayer:_buttons[i]];
  }
  _current = 2;
  [self selectMenu:_current];

  self.layer.layoutManager = [CAConstraintLayoutManager layoutManager];
  [self.layer addSublayer:_subtitle];
  [self.layer addSublayer:_menu];
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
  return (id<CAAction>)[NSNull null];
}

- (void)frameChanged
{
  MyOpenGLLayer* layer = (MyOpenGLLayer*)self.layer;
  if ([layer frameChanged]) {
    CGFloat s = layer.contentsScale;
    CGFloat h = layer.movieRect.size.height / s;
    CGFloat y = layer.movieRect.origin.y / s;
    
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
    _menuHeight = self.bounds.size.height * 128.0 / 1080.0;
    _menu.bounds = CGRectMake(0, 0, self.bounds.size.width, _menuHeight);
    if (_menuHidden) {
      _menu.position = CGPointMake(0, -_menuHeight);
    } else {
      _menu.position = CGPointMake(0, 0);
    }
    CGFloat x = (self.bounds.size.width - _menuHeight * BUTTON_COUNT) / 2;
    for (int i = 0; i < BUTTON_COUNT; i++) {
      _buttons[i].bounds = CGRectMake(0, 0, _menuHeight, _menuHeight);
      _buttons[i].position = CGPointMake(x, 0);
      x += _menuHeight;
    }
    [self.layer setNeedsLayout];
    
    [CATransaction commit];
  }
}

- (void)open:(NSString *)path
{
  MyOpenGLLayer* layer = (MyOpenGLLayer*)self.layer;
  layer.subtitleDelegate = self;
  [layer open:path];
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
  MyOpenGLLayer* layer = (MyOpenGLLayer*)self.layer;
  NSString* newString = [layer.decoder subtitleString];
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
      [self menuPressed];
      break;
    case '\r':
      [self enterPressed];
      break;
    case NSLeftArrowFunctionKey:
      [self leftPressed];
      break;
    case NSRightArrowFunctionKey:
      [self rightPressed];
      break;
    default:
      break;
  }
}

- (void)menuPressed
{
  if (_menuHidden) {
    [self.layer addSublayer:_menu];
    _menu.position = CGPointMake(0, 0);
    _menuHidden = NO;
  } else {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* ctx) {
      _menu.position = CGPointMake(0, -_menuHeight);
    } completionHandler:^{
      [_menu removeFromSuperlayer];
      _menuHidden = YES;
    }];
  }
}

- (void)enterPressed
{
  if (_menuHidden) {
    
  }
}

- (void)leftPressed
{
  if (_menuHidden) {
  } else {
    [self moveCurrentMenu:-1];
  }
}

- (void)rightPressed
{
  if (_menuHidden) {
  } else {
    [self moveCurrentMenu:1];
  }
}

- (void)moveCurrentMenu:(int)dir
{
  [self unselectMenu:_current];
  _current = (_current + BUTTON_COUNT + dir) % BUTTON_COUNT;
  [self selectMenu:_current];
}

- (void)selectMenu:(int)i
{
  _buttons[i].contents = _images[i][ON];
  _buttons[i].shadowColor = [NSColor whiteColor].CGColor;
  _buttons[i].shadowOpacity = 1.0;
  _buttons[i].shadowOffset = CGSizeMake(0, 0);
}

- (void)unselectMenu:(int)i
{
  _buttons[i].contents = _images[i][OFF];
  _buttons[i].shadowOpacity = 0.0;
}

- (BOOL)acceptsFirstResponder
{
  return YES;
}

@end
