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

@interface CubeModel: RenderObject{
    // модель
    GLint _cubeVAO;
    GLint _cubeElementsCount;
    
    // шейдер
    GLint _cubeMVPLocation;
}

@end
