//
//  SubtitleBuf.m
//  Jap
//
//  Created by Jake Song on 3/23/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "SubtitleBuf.h"
#import "Decoder.h"

@implementation SubtitleBuf

- (id)init
{
  self = [super init];
  if (self) {
    _q = dispatch_queue_create("jap.subtitle", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)setDecoder:(Decoder *)decoder stream:(AVStream*)stream
{
  _decoder = decoder;
  _stream = stream;
}

- (void)start
{
  dispatch_async(_q, ^{
    AVSubtitle sub;
    int got_subtitle;
    AVPacket packet;
    
    while (!_quit) {
      @autoreleasepool {
        while (!_quit && ![_decoder.subtitleQue isEmpty]) {
          [_decoder.subtitleQue get:&packet];
          avcodec_decode_subtitle2(_stream->codec, &sub, &got_subtitle, &packet);
          if (got_subtitle) {
            NSLog(@"%s", sub.rects[0]->ass);
            _layer.string = [NSString stringWithUTF8String:sub.rects[0]->ass];
            dispatch_async(dispatch_get_main_queue(), ^{
              [_layer setNeedsDisplay];
            });
          }
          av_free_packet(&packet);
        }
        usleep(100000);
      }
    }
  });
}

@end
