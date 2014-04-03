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
#import "MediaControlLayer.h"

@interface MyView : NSView <SubtitleDelegate, KeyHandler>
{
  CATextLayer* _subtitle;
  NSFont* _subtitleFont;
  
  BOOL _resizing;

  id<KeyHandler> _handler;
  MediaControlLayer* _mediaControl;
}

- (void)open:(NSString*)path;
- (void)displaySubtitle;
- (void)takeFocus;

@end
