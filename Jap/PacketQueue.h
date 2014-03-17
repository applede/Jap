//
//  PacketQueue.h
//  Jap
//
//  Created by Jake Song on 3/17/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavformat/avformat.h>

@interface PacketQueue : NSObject
{
  int _size;
  int _count;
  int _front;
  int _back;
  NSLock* _lock;
  AVPacket* _packets;
}

- initWithSize:(int)size;
- (BOOL)isFull;
- (BOOL)isEmpty;
- (void)put:(AVPacket*)packet;
- (void)get:(AVPacket*)packet;

@end
