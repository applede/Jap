//
//  MediaControlLayer.h
//  Jap
//
//  Created by Jake Song on 4/4/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlurLayer.h"

#define BUTTON_COUNT 6

@class MyView;

@protocol KeyHandler <NSObject>

- (void)menuPressed;
- (void)enterPressed;
- (void)spacePressed;
- (void)escPressed;
- (void)leftPressed;
- (void)rightPressed;

@end

@interface MediaControlLayer : BlurLayer <KeyHandler>
{
  int _current;
  CALayer* _buttons[BUTTON_COUNT];
  /// we need one more image for play icon.
  NSImage* _images[BUTTON_COUNT + 1][2];
  BOOL _playing;
}

@property (weak) MyView* view;

@end
