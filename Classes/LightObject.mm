//
//  LightObject.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "LightObject.h"
#import "GlobalValues.h"

@implementation LightObject

-(id)init{
    if ((self = [super init])) {
        self.lightPos = vec3(100, 100, 100);
        self.lightTargetPos = vec3(0.0, 0.0, 0.0);
    }
    return self;
}

@end
