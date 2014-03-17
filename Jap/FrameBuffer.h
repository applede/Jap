//
//  VideoQueue.h
//  Jap
//
//  Created by Jake Song on 3/16/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TEXTURE_COUNT		5

@interface FrameBuffer : NSObject
{
  int _count;
  BOOL _quit;
  int _front;
  int _back;
  dispatch_semaphore_t _sema;
}

@property int size;
@property GLubyte* data;
@property int width;
@property int height;

- (GLubyte*)data:(int)i;
- (GLubyte*)frontData;
- (void)generate;
- (void)start;

@end
