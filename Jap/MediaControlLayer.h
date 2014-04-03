//
//  MediaControlLayer.h
//  Jap
//
//  Created by Jake Song on 4/4/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#define BUTTON_COUNT 6

@class MyView;

@protocol KeyHandler <NSObject>

- (void)menuPressed;
- (void)enterPressed;
- (void)leftPressed;
- (void)rightPressed;

@end

@interface MediaControlLayer : CALayer <KeyHandler>
{
  int _current;
  CALayer* _buttons[BUTTON_COUNT];
  NSImage* _images[BUTTON_COUNT][2];
}

@property (weak) MyView* view;

@end
