//
//  BlurLayer.m
//  Jap
//
//  Created by Jake Song on 4/5/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import "BlurLayer.h"

@implementation BlurLayer

- (id)init
{
  self = [super init];
  if (self) {
    self.masksToBounds = YES;
    self.backgroundColor = [[NSColor colorWithCalibratedWhite:0.6 alpha:0.7] CGColor];
    self.needsDisplayOnBoundsChange = YES;
    CIFilter* saturationFilter = [CIFilter filterWithName:@"CIColorControls"];
    [saturationFilter setDefaults];
    [saturationFilter setValue:@2.0 forKey:@"inputSaturation"];
    CIFilter* clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    [clampFilter setDefaults];
    [clampFilter setValue:[NSValue valueWithBytes:&CGAffineTransformIdentity objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    CIFilter* blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setDefaults];
    [blurFilter setValue:@20.0 forKey:@"inputRadius"];
    self.backgroundFilters = @[saturationFilter, clampFilter, blurFilter];
    [self setNeedsDisplay];
  }
  return self;
}

@end
