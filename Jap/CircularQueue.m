//
//  CircularQueue.m
//  Jap
//
//  Created by Jake Song on 3/30/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "CircularQueue.h"

@implementation CircularQueue

- initSize:(int)size
{
  self = [super init];
  if (self) {
    _size = size;
    _count = 0;
    _front = 0;
    _back = 0;
    _objs = (id __strong*)calloc(_size, sizeof(id));
    _lock = [[NSLock alloc] init];
  }
  return self;
}

-(void)dealloc
{
  for (int i = 0; i < _size; i++) {
    _objs[i] = nil;
  }
}

- (BOOL)isEmpty
{
  BOOL r;
  [_lock lock];
  r = (_count == 0);
  [_lock unlock];
  return r;
}

- (BOOL)isFull
{
  BOOL r;
  [_lock lock];
  r = (_count >= _size);
  [_lock unlock];
  return r;
}

- (void)add:obj
{
  assert(_count < _size);
  [_lock lock];
  _objs[_back] = obj;
  _back = (_back + 1) % _size;
  _count++;
  [_lock unlock];
}

- remove
{
  assert(_count > 0);
  id r;
  [_lock lock];
  r = _objs[_front];
  _front = (_front + 1) % _size;
  _count--;
  [_lock unlock];
  return r;
}

@end
