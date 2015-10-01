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

@interface SkyModel3D: RenderObject{
    // модель
    GLint _modelVAO;
    GLuint _modelElementsCount;
    GLuint _modelElementsType;
    
    // текстуры
    GLint _modelTexture;
    GLint _normalsTexture;
    
    // шейдер
    GLint _projMatrixLocation;
    GLint _viewMatrixLocation;
    GLint _modelMatrixLocation;
    GLint _modelCubemapTextureLocation;
    GLint _modelTextureLocation;
    GLint _normalsTextureLocation;
    GLint _cameraPosLocation;
    GLint _lengthCorrectionLocation;
}

@property(nonatomic, assign) GLuint boxTexture;

-(id)initWithObjFilename:(NSString*)filename;
-(id)initWithFilename:(NSString *)filename;

@end
