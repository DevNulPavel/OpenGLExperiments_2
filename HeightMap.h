//
//  Model3D.h
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "glUtil.h"
#import "RenderObject.h"
#import "glm.hpp"
#import "ext.hpp"

using namespace glm;

@interface HeightMap: RenderObject{
    uint _width;
    uint _height;
    
    // фреймбуффер
    GLuint _fbo;
    GLuint _pixelBuffersSize;
    GLuint _vertexPixelBuffer;
    GLuint _normalsPixelBuffer;
    GLuint _texcoordPixelBuffer;
    
    // модель
    GLuint _modelVAO;
    GLint _modelElementsCount;
    
    // текстуры
    GLint _heightTexture;
    GLint _modelTexture;
    
    // шейдер
    GLint _mvpMatrixLocation;
    GLint _mvMatrixLocation;
    GLint _projMatrixLocation;
    GLint _viewMatrixLocation;
    GLint _modelMatrixLocation;
    GLint _modelTextureLocation;
    GLuint _lightPosWorlLocation;
}

-(id)init;

@end
