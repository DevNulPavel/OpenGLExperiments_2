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

using namespace glm;

@interface Skybox: RenderObject{
    // модель
    GLuint _skyboxVAO;
    GLint _skyboxElementsCount;
    
    // тестура
    GLuint _skyboxTexture;
    
    // шейдер
    GLint _skyboxTextureLocation;
    GLuint _skyboxModelViewLocation;
}

-(GLint)texture;

@end
