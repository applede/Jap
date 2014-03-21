//
//  PacketQueue.m
//  Jap
//
//  Created by Jake Song on 3/17/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "PacketQueue.h"

@implementation PacketQueue

- (id)initWithSize:(int)size
{
  self = [super init];
  if (self) {
    _count = 0;
    _size = size;
    _front = 0;
    _back = 0;
    _lock = [[NSLock alloc] init];
    _packets = calloc(_size, sizeof(AVPacket));
  }
  return self;
}

- (void)dealloc
{
  free(_packets);
}

- (BOOL)isEmpty
{
  return _count == 0;
}

- (BOOL)isFull
{
  return _count == _size;
}

- (void)put:(AVPacket *)pkt
{
  if (av_dup_packet(pkt) < 0)
    return;
  [_lock lock];
  _packets[_back] = *pkt;
  _back = (_back + 1) % _size;
  _count++;
  assert(_count <= _size);
  [_lock unlock];
}

- (void)get:(AVPacket *)pkt
{
  [_lock lock];
  *pkt = _packets[_front];
  _front = (_front + 1) % _size;
  _count--;
  assert(_count >= 0);
  [_lock unlock];
}

@end
