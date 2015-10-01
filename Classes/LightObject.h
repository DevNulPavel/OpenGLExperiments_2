//
//  LightObject.h
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import <Foundation/Foundation.h>
#import "glm.hpp"
#import "ext.hpp"

using namespace glm;



@interface LightObject : NSObject

@property (nonatomic, assign) vec3 lightPos;
@property (nonatomic, assign) vec3 lightTargetPos;

@end
