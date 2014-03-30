//
//  MyView.m
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "MyView.h"
#import "MyOpenGLLayer.h"

@implementation MyView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
      [self setWantsBestResolutionOpenGLSurface:YES];
      [self setLayer:[MyOpenGLLayer layer]];
      [self setWantsLayer:YES];
      [self makeSubtitleLayer];
    }
    return self;
}

- (void)viewDidChangeBackingProperties
{
  _text.contentsScale = [self.window backingScaleFactor];
  [super viewDidChangeBackingProperties];
}

- (void)makeSubtitleLayer
{
  _text = [CATextLayer layer];
  _text.delegate = self;
  _text.alignmentMode = kCAAlignmentCenter;
  _text.font = (__bridge CFTypeRef)@"HelveticaNeue-Light";
  _text.shadowOpacity = 1.0;
  _text.shadowOffset = CGSizeMake(1.0, -2.0);
  _text.shadowRadius = 2.0;
  self.layer.layoutManager = [CAConstraintLayoutManager layoutManager];
  [self.layer addSublayer:_text];
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
    
    _text.fontSize = h * 0.08;
    [_text setConstraints:@[[CAConstraint constraintWithAttribute:kCAConstraintMidX
                                                  relativeTo:@"superlayer"
                                                   attribute:kCAConstraintMidX],
                            [CAConstraint constraintWithAttribute:kCAConstraintMinY
                                                    relativeTo:@"superlayer"
                                                     attribute:kCAConstraintMinY offset:y]]];
    [self.layer setNeedsLayout];
  }
}

- (void)open:(NSString *)path
{
  MyOpenGLLayer* layer = (MyOpenGLLayer*)self.layer;
  layer.decoder.subtitle = _text;
  [layer open:path];
  [self frameChanged];
}

- (void)windowDidResize:(NSNotification*)notification
{
  [self frameChanged];
}

@end
