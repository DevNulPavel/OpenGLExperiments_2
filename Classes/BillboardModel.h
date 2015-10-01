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
#import <vector>

using namespace glm;

@interface BillboardModel: RenderObject{
    // биллборд
    GLint _billboardPointVAO;
    GLint _billboardPointCount;

    // текстура
    GLuint _billboardTexture;
    
    // шейдер
    GLint _billboardTextureLocation;
    GLint _billboardModelLocation;
    GLint _billboardViewlLocation;
    GLint _billboardProjLocation;
    GLint _billboardCameraPosLocation;
}

-(id)initWithPositions:(std::vector<vec3>) positions;
-(id)initOne;

@end
