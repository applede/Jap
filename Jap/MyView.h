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

@interface MyView : NSView <SubtitleDelegate>
{
  CATextLayer* _text;
  NSFont* _subtitleFont;
}

- (void)open:(NSString*)path;
- (void)displaySubtitle;

@end
