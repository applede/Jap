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
      _text.frame = CGRectMake(0, 100, 100, 50);
      _text.string = @"Hello";
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
  [(MyOpenGLLayer*)self.layer frameChanged];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
