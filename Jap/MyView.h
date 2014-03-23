//
//  MyView.h
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface MyView : NSView
{
  CATextLayer* _text;
}

- (void)open:(NSString*)path;

@end
