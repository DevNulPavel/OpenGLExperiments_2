//
//  Model3D.h
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import <Foundation/Foundation.h>
#import "glUtil.h"
#import "RenderObject.h"
#import "glm.hpp"
#import "ext.hpp"
#import "Camera.h"

using namespace glm;

@interface ParticlesModel: RenderObject{
    // модель
    GLint _particlesVAO;
    GLint _particlesPointsCount;
    
    // шейдер
    GLint _particlesTimeLocation;
    GLint _particlesMVPLocation;
}

@end
