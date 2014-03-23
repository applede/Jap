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
      [self setWantsLayer:YES];
      _text = [CATextLayer layer];
      _text.frame = CGRectMake(0, 0, frame.size.width, 50);
      _text.alignmentMode = kCAAlignmentCenter;
      _text.font = (__bridge CFTypeRef)@"HelveticaNeue-Light";
      [self.layer addSublayer:_text];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged:) name:NSViewFrameDidChangeNotification object:nil];
      [self setPostsFrameChangedNotifications:YES];
    }
    return self;
}

- (CALayer *)makeBackingLayer
{
  return [MyOpenGLLayer layer];
}

- (void)viewDidChangeBackingProperties
{
  _text.contentsScale = [self.window backingScaleFactor];
  [super viewDidChangeBackingProperties];
}

- (void)frameChanged:(NSNotification*)notification
{
  MyOpenGLLayer* layer = (MyOpenGLLayer*)self.layer;
  [layer frameChanged];
  CGFloat s = layer.contentsScale;
  CGFloat w = layer.movieRect.size.width / s;
  CGFloat h = layer.movieRect.size.height / s;
  CGFloat y = layer.movieRect.origin.y / s;
  h = h * 0.10;
  y = h;
  _text.frame = CGRectMake(0, y, w, h);
  _text.fontSize = h * 0.8;
  _text.string = @"Hello World 초속 5cm yg";
  _text.shadowOpacity = 1.0;
  _text.shadowOffset = CGSizeMake(1.0, -2.0);
  _text.shadowRadius = 2.0;
}

- (void)open:(NSString *)path
{
  [(MyOpenGLLayer*)self.layer open:path];
  [self frameChanged:nil];
}

@end
