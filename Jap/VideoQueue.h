//
//  VideoQueue.h
//  Jap
//
//  Created by Jake Song on 3/17/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

#define TEXTURE_COUNT		5

@interface VideoQueue : NSObject
{
  double _time[TEXTURE_COUNT];
  GLubyte* _data;
}

@property int size;
@property int width;
@property int height;

- (double)time:(int)i;
- (void)setTime:(double)t of:(int)i;
- (GLubyte*)data:(int)i;

@end
