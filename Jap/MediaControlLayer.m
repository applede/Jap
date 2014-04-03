//
//  MediaControlLayer.m
//  Jap
//
//  Created by Jake Song on 4/4/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "MediaControlLayer.h"
#import "MyView.h"

#define OFF 0
#define ON  1
#define PAUSE 2
#define PLAY  6

@implementation MediaControlLayer

- (id)init
{
  self = [super init];
  if (self) {
    static NSString* imageNames[BUTTON_COUNT+1][2] = {
      {@"skip-to-start-128-black.png", @"skip-to-start-128-white.png"},
      {@"rewind-128-black.png", @"rewind-128-white.png"},
      {@"pause-128-black.png", @"pause-128-white.png"},
      {@"stop-128-black.png", @"stop-128-white.png"},
      {@"fast-forward-128-black.png", @"fast-forward-128-white.png"},
      {@"end-128-black.png", @"end-128-white.png"},
      {@"play-128-black.png", @"play-128-white.png"},
    };
    for (int i = 0; i < BUTTON_COUNT + 1; i++) {
      _images[i][OFF] = [NSImage imageNamed:imageNames[i][OFF]];
      _images[i][ON] = [NSImage imageNamed:imageNames[i][ON]];
    }
    for (int i = 0; i < BUTTON_COUNT; i++) {
      _buttons[i] = [CALayer layer];
      _buttons[i].contents = _images[i][OFF];
      _buttons[i].anchorPoint = CGPointMake(0, 0);
      [self addSublayer:_buttons[i]];
    }
    _current = 2;
    [self select:_current];
    _playing = YES;
  }
  return self;
}

- (void)setBounds:(CGRect)bounds
{
  [super setBounds:bounds];
  CGFloat h = self.bounds.size.height;
  CGFloat x = (self.bounds.size.width - h * BUTTON_COUNT) / 2;
  for (int i = 0; i < BUTTON_COUNT; i++) {
    _buttons[i].bounds = CGRectMake(0, 0, h, h);
    _buttons[i].position = CGPointMake(x, 0);
    x += h;
  }
}

- (void)setContentsScale:(CGFloat)f
{
  [super setContentsScale:f];
  for (int i = 0; i < BUTTON_COUNT; i++) {
    _buttons[i].contentsScale = f;
  }
}

- (void)menuPressed
{
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext* ctx) {
    self.position = CGPointMake(0, -self.bounds.size.height);
  } completionHandler:^{
    [self removeFromSuperlayer];
  }];
  [_view takeFocus];
}

- (void)enterPressed
{
  if (_current == PAUSE) {
    _playing = !_playing;
    if (_playing) {
      _buttons[PAUSE].contents = _images[PAUSE][ON];
    } else {
      _buttons[PAUSE].contents = _images[PLAY][ON];
    }
  }
}

- (void)leftPressed
{
  [self moveCurrent:-1];
}

- (void)rightPressed
{
  [self moveCurrent:1];
}

- (void)moveCurrent:(int)dir
{
  [self unselect:_current];
  _current = (_current + BUTTON_COUNT + dir) % BUTTON_COUNT;
  [self select:_current];
}

- (void)select:(int)i
{
  _buttons[i].contents = _images[i][ON];
  _buttons[i].shadowColor = [NSColor whiteColor].CGColor;
  _buttons[i].shadowOpacity = 1.0;
  _buttons[i].shadowOffset = CGSizeMake(0, 0);
}

- (void)unselect:(int)i
{
  _buttons[i].contents = _images[i][OFF];
  _buttons[i].shadowOpacity = 0.0;
}

@end
