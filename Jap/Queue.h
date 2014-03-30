//
//  Queue.h
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Time <NSObject>

- (double)time;

@end

@interface Queue : NSObject
{
  int _size;
  NSMutableArray* _array;
  NSLock* _lock;
}

- initSize:(int)size;
- (BOOL)isFull;
- (BOOL)isEmpty;
- front;
- (void)add:(id<Time>)element;
- get;
- getBefore:(double)time;

@end
