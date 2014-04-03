//
//  MyView.h
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "MyOpenGLLayer.h"

#define BUTTON_COUNT 6

@interface MyView : NSView <SubtitleDelegate>
{
  CATextLayer* _subtitle;
  NSFont* _subtitleFont;
  
  CALayer* _menu;
  CGFloat _menuHeight;
  BOOL _menuHidden;
 
  CALayer* _buttons[BUTTON_COUNT];
  NSImage* _images[BUTTON_COUNT][2];
  int _current;
  
  BOOL _resizing;
}

- (void)open:(NSString*)path;
- (void)displaySubtitle;

@end
