//
//  MyView.m
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "MyView.h"
#import "MyOpenGLLayer.h"

void resetFilters(CALayer* layer)
{
  layer.masksToBounds = YES;
  layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.5 alpha:0.6] CGColor];
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
  _play.contentsScale = f;
  _stop.contentsScale = f;
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
  
  _play = [CALayer layer];
  _play.contents = [NSImage imageNamed:@"pause-128-black.png"];
  _play.anchorPoint = CGPointMake(0, 0);
  
  _stop = [CALayer layer];
  _stop.contents = [NSImage imageNamed:@"stop-128-black.png"];
  _stop.anchorPoint = CGPointMake(0, 0);

  self.layer.layoutManager = [CAConstraintLayoutManager layoutManager];
  [self.layer addSublayer:_subtitle];
  [self.layer addSublayer:_menu];
  [_menu addSublayer:_play];
  [_menu addSublayer:_stop];
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
    _play.bounds = CGRectMake(0, 0, _menuHeight, _menuHeight);
    CGFloat x = self.bounds.size.width / 2 - _menuHeight / 2;
    _play.position = CGPointMake(x, 0);
    x += _menuHeight;
    _stop.bounds = CGRectMake(0, 0, _menuHeight, _menuHeight);
    _stop.position = CGPointMake(x, 0);
    [self.layer setNeedsLayout];
  }
}

- (void)open:(NSString *)path
{
  MyOpenGLLayer* layer = (MyOpenGLLayer*)self.layer;
  layer.subtitleDelegate = self;
  [layer open:path];
  [self frameChanged];
}

- (void)windowDidResize:(NSNotification*)notification
{
  [self frameChanged];
}

- (void)displaySubtitle
{
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

- (BOOL)acceptsFirstResponder
{
  return YES;
}

@end
