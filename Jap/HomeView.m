//
//  HomeView.m
//  Jap
//
//  Created by Jake Song on 4/5/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "HomeView.h"
#import "Section.h"

#define SLIDE_SHOW_DELAY  7

@implementation HomeView

- (id)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code here.
    [self setWantsLayer:YES];
    [self setWantsBestResolutionOpenGLSurface:YES];
    [self setLayerUsesCoreImageFilters:YES];

    self.layer.backgroundColor = [[NSColor blackColor] CGColor];
    self.layer.contentsGravity = kCAGravityResizeAspect;

    _bar = [BlurLayer layer];
    _bar.anchorPoint = CGPointMake(0, 0);

    _cursor = [BlurLayer layer];
    _cursor.backgroundColor = [[NSColor colorWithCalibratedWhite:0.2 alpha:0.6] CGColor];
    _cursor.anchorPoint = CGPointMake(0, 0);

    _layers = [[NSMutableArray alloc] init];

    [self.layer addSublayer:_bar];
//    [self.layer addSublayer:_cursor];

    [self frameChanged];
  }
  return self;
}

- (void)setSections:(NSArray *)sections
{
  _sections = sections;
  __block CGFloat x = (self.bounds.size.width - _sectionWidth) / 2;
  CGFloat scale = [self.window backingScaleFactor];
  [_sections enumerateObjectsUsingBlock:^(Section* section, NSUInteger idx, BOOL *stop) {
    CATextLayer* layer = [CATextLayer layer];
    layer.bounds = CGRectMake(0, 0, _sectionWidth, _sectionHeight);
    layer.anchorPoint = CGPointMake(0, 0);
    layer.position = CGPointMake(x, _sectionHeight);
    layer.string = section.name;
    layer.alignmentMode = kCAAlignmentCenter;
    layer.font = (__bridge CFTypeRef)@"HelveticaNeue-Light";
    layer.fontSize = _sectionHeight * 0.8;
    layer.foregroundColor = [[NSColor blackColor] CGColor];
    layer.contentsScale = scale;
    [_layers addObject:layer];
    [self.layer addSublayer:layer];
    x += _sectionWidth;
  }];
  [self select:0];
  [self showRandomFanart];
}

- (void)showRandomFanart
{
  NSImage* image = [[NSImage alloc] initWithContentsOfFile:[_sections[0] randomFanart]];

  NSImageRep* rep = image.representations[0];
  if (rep.pixelsWide != rep.size.width) {
    NSSize size = NSMakeSize(rep.pixelsWide, rep.pixelsHigh);
    NSImage* newImage = [[NSImage alloc] initWithSize:size];
    [newImage lockFocus];
    [image drawInRect:NSMakeRect(0, 0, size.width, size.height)];
    [newImage unlockFocus];
    image = newImage;
  }

  self.layer.contents = image;
  CABasicAnimation* crossfade = [CABasicAnimation animationWithKeyPath:@"contents"];
  crossfade.duration = 0.5;
  crossfade.removedOnCompletion = YES;
  [self.layer addAnimation:crossfade forKey:nil];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SLIDE_SHOW_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self showRandomFanart];
  });
}

- (void)windowDidResize:(NSNotification*)notification
{
  [self frameChanged];
}

- (void)frameChanged
{
  _sectionWidth = (self.bounds.size.width + self.bounds.size.width * 0.09375 * 2) / 5;
  _sectionHeight = MIN(self.bounds.size.height, self.bounds.size.width * 1080 / 1920) / 6.75;

  [CATransaction begin];
  [CATransaction setDisableActions:YES];

  CGFloat by = _sectionHeight;
  _bar.bounds = CGRectMake(0, 0, self.bounds.size.width, _sectionHeight);
  _bar.position = CGPointMake(0, by);

  __block CGFloat x = (self.bounds.size.width - _sectionWidth) / 2;
  _cursor.bounds = CGRectMake(0, 0, _sectionWidth, _sectionHeight);
  _cursor.position = CGPointMake(x, by);

  x = (self.bounds.size.width - _sectionWidth) / 2;
  [_layers enumerateObjectsUsingBlock:^(CATextLayer* layer, NSUInteger idx, BOOL *stop) {
    layer.bounds = CGRectMake(0, 0, _sectionWidth, _sectionHeight);
    layer.position = CGPointMake(x, _sectionHeight);
    layer.fontSize = _sectionHeight * 0.8;
    x += _sectionWidth;
  }];

  [CATransaction commit];
}

- (void)select:(int)i
{
  CATextLayer* layer = _layers[i];
  layer.foregroundColor = [[NSColor whiteColor] CGColor];
  layer.shadowColor = [[NSColor whiteColor] CGColor];
  layer.shadowOpacity = 1.0;
  layer.shadowOffset = CGSizeMake(0, 0);
}

- (void)unselect:(int)i
{
  CATextLayer* layer = _layers[i];
  layer.foregroundColor = [[NSColor blackColor] CGColor];
  layer.shadowOpacity = 0.0;
}

@end
