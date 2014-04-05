//
//  HomeView.h
//  Jap
//
//  Created by Jake Song on 4/5/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BlurLayer.h"

@interface HomeView : NSView <NSWindowDelegate>
{
  NSArray* _sections;
  BlurLayer* _bar;
  BlurLayer* _cursor;
  NSMutableArray* _layers;
  CGFloat _sectionWidth;
  CGFloat _sectionHeight;
  dispatch_queue_t _background;
}

- (void)setSections:(NSArray*)sections;

@end
