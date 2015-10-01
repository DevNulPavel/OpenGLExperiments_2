//
//  Model3D.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "Skybox.h"
#import "GlobalValues.h"
#import "VAOCreate.h"
#import "TextureCreate.h"
#import "ShadersCache.h"
#import "GLStatesCache.h"

@implementation Skybox

-(id)init{
    if ((self = [super init])) {
        _skyboxVAO = skyboxVAO(&_skyboxElementsCount);
        _skyboxTexture = buildSkyboxTexture();
        
        [self generateShader];
    }
    return self;
}

-(void)generateShader{
    // скайбокс
    _skyboxTextureLocation = glGetUniformLocation(ShadI.skyboxShader, "u_cubemapTexture");
    _skyboxModelViewLocation = glGetUniformLocation(ShadI.skyboxShader, "u_modelViewProj");
}

-(GLint)texture{
    return _skyboxTexture;
}

-(void)renderModelFromCamera:(Camera*)cameraObj light:(LightObject*)light toShadow:(BOOL)toShadowMap customProj:(const mat4*)customProj{
    // обновляем матрицу модели (ОБРАТНЫЙ ПОРЯДОК)
    mat4 model = scale(mat4(1.0), GlobI.worldSize/vec3(2.0));
    
    // камера вида
    mat4 camera = [cameraObj cameraMatrix];
    
    // проекция
    mat4 projection;
    if (customProj) {
        projection = *customProj;
    }else{
        projection = [self projectionMatrix];
    }
    
    // умножаем матрицу проекции на вью на матрицу модели и получаем матрицу для домножения на точку
    mat4 mvp = projection * camera * model;
    
    // шейдер
    [StatesI useProgramm:ShadI.skyboxShader];
    
    [StatesI setUniformInt:_skyboxTextureLocation val:0];
    [StatesI activateTexture:GL_TEXTURE0 type:GL_TEXTURE_CUBE_MAP texId:_skyboxTexture];
    
    [StatesI setUniformMat4:_skyboxModelViewLocation val:mvp];
    
    // старые режимы
    BOOL isEnabledCullFace = [StatesI isEnabled:GL_CULL_FACE];
    GLint oldCullFaceMode;
    glGetIntegerv(GL_CULL_FACE_MODE, &oldCullFaceMode);
    GLint oldDepthTestMode;
    glGetIntegerv(GL_DEPTH_FUNC, &oldDepthTestMode);
    
    [StatesI enableState:GL_DEPTH_TEST];
    [StatesI enableState:GL_CULL_FACE];     // не рисует заднюю часть
    glFrontFace(GL_CCW);        // передняя часть при обходе против часовой стрелки
    glCullFace(GL_FRONT);
    glDepthFunc(GL_LEQUAL);
    
    [StatesI bindVAO:_skyboxVAO];
    glDrawElements(GL_TRIANGLES, _skyboxElementsCount, GL_UNSIGNED_INT, 0);
    
    if (isEnabledCullFace == FALSE) {
        [StatesI disableState:GL_CULL_FACE];     // не рисует заднюю часть
    }
    glCullFace(oldCullFaceMode);
    glDepthFunc(oldDepthTestMode);
}

-(void)dealloc{
    destroyVAO(_skyboxVAO);
    // TODO: удаление текстур
    [super dealloc];
}

@end