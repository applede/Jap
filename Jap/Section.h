//
//  Section.h
//  Jap
//
//  Created by Jake Song on 4/5/14.
//  Copyright (c) 2014 Jake Song. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Section : NSObject

@property NSString* name;
@property NSArray* folders;
@property NSMutableArray* fanarts;

- initName:(NSString*)name folders:(NSArray*)folders;
- (NSString*)randomFanart;

@end
