//
//  Model3D.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "CubeModel.h"
#import "GlobalValues.h"
#import "ObjModelVAO.h"
#import "VAOCreate.h"
#import "TextureCreate.h"
#import "GlobalValues.h"
#import "ShadersCache.h"
#import "GLStatesCache.h"

@implementation CubeModel

-(id)init{
    if ((self = [super init])) {
        _cubeVAO = cubeVAO(&_cubeElementsCount);
        
        [self setDefaultValues];
        [self generateShader];
    }
    return self;
}

-(void)setDefaultValues{
    self.modelPos = vec3(0.0);
}

-(void)generateShader{
    // куб
    _cubeMVPLocation = glGetUniformLocation(ShadI.cubeShader, "u_mvp");
}

-(void)renderModelFromCamera:(Camera*)cameraObj light:(LightObject*)light toShadow:(BOOL)toShadowMap customProj:(const mat4 *)customProj{
    // обновляем матрицу модели (ОБРАТНЫЙ ПОРЯДОК)    
    mat4 model = [self modelTransformMatrix];
    
    mat4 camera = [cameraObj cameraMatrix];
    
    // вычислим матрицу проекции в массив projection
    mat4 projection = [self projectionMatrix];
    
    // умножаем матрицу проекции на вью на матрицу модели и получаем матрицу для домножения на точку
    mat4 mvp = projection * camera * model;
    
    [StatesI useProgramm:ShadI.cubeShader];
    [StatesI setUniformMat4:_cubeMVPLocation val:mvp];
    
    [StatesI bindVAO:_cubeVAO];
    glDrawElements(GL_TRIANGLES, _cubeElementsCount, GL_UNSIGNED_INT, 0);
}

-(void)dealloc{
    destroyVAO(_cubeVAO);
    // TODO: удаление текстур
    [super dealloc];
}

@end