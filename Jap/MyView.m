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
      [self setWantsLayer:YES];
      CATextLayer* text = [CATextLayer layer];
      text.frame = CGRectMake(0, 100, 100, 50);
      text.string = @"Hello";
      [self.layer addSublayer:text];
    }
    return self;
}

- (CALayer *)makeBackingLayer
{
  return [MyOpenGLLayer layer];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
