//
//  AudioQueue.h
//  Jap
//
//  Created by Jake Song on 3/20/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>

@interface AudioQueue : NSObject
{
}

@property AVStream* stream;

- (void)put:(AVPacket*)packet;

@end
