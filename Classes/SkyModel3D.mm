//
//  Model3D.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "SkyModel3D.h"
#import "GlobalValues.h"
#import "ObjModelVAO.h"
#import "VAOCreate.h"
#import "TextureCreate.h"
#import "GlobalValues.h"
#import "ShadersCache.h"
#import "GLStatesCache.h"

@implementation SkyModel3D

-(id)initWithObjFilename:(NSString *)filename{
    if ((self = [super init])) {
        BoudndingBox box;
        _modelVAO = buildObjVAO(filename, &_modelElementsCount, box);
        _modelElementsType = GL_UNSIGNED_INT;
        _modelTexture = buildTexture(filename);
        _normalsTexture = buildTexture([NSString stringWithFormat:@"%@_normals", filename]);

        self.boundBox = box;
        
        [self setDefaultValues];
        [self generateShader];
    }
    return self;
}

-(id)initWithFilename:(NSString *)filename{
    if ((self = [super init])) {
        BoudndingBox box;
        _modelVAO = buildModelVAO(&_modelElementsCount, &_modelElementsType, box);
        _modelTexture = buildTexture(filename);
        _normalsTexture = buildTexture([NSString stringWithFormat:@"%@_normals", filename]);
        
        self.boundBox = box;
        
        [self setDefaultValues];
        [self generateShader];
    }
    return self;
}

-(void)setDefaultValues{
    self.modelPos = vec3(0.0);
}

-(void)generateShader{
    _modelMatrixLocation = glGetUniformLocation(ShadI.skyModelShaderProgram, "u_modelMatrix");
    _viewMatrixLocation =  glGetUniformLocation(ShadI.skyModelShaderProgram, "u_viewMatrix");
    _projMatrixLocation =  glGetUniformLocation(ShadI.skyModelShaderProgram, "u_projectionMatrix");
    _modelTextureLocation = glGetUniformLocation(ShadI.skyModelShaderProgram, "u_texture");
    _normalsTextureLocation = glGetUniformLocation(ShadI.skyModelShaderProgram, "u_normalsTexture");
    _modelCubemapTextureLocation = glGetUniformLocation(ShadI.skyModelShaderProgram, "u_cubemapTexture");
    _cameraPosLocation = glGetUniformLocation(ShadI.skyModelShaderProgram, "u_glSpaceCameraPos");
    _lengthCorrectionLocation = glGetUniformLocation(ShadI.skyModelShaderProgram, "u_lengthCorrection");
}

-(void)renderModelFromCamera:(Camera*)cameraObj light:(LightObject*)light toShadow:(BOOL)toShadowMap customProj:(const mat4*)customProj{
    
    // обновляем матрицу модели (ОБРАТНЫЙ ПОРЯДОК)
    mat4 modelMat = [self modelTransformMatrix];

    // вид из точки света
    mat4 shadowCamera = lookAt(light.lightPos, light.lightTargetPos, vec3(0.0, 1.0, 0.0));
    
    // камера вида
    mat4 camera;
    if (toShadowMap == FALSE) {
        camera = [cameraObj cameraMatrix];
    }else{
        camera = shadowCamera;
    }

    // проекция
    mat4 projection = [self projectionMatrix];

    mat4 mvp = projection * camera * modelMat;
    if ([self isVisible:mvp] == FALSE) {
        return;
    }
    
    vec3 glSpaceCameraPos = [cameraObj cameraPos];

    // коррекция для отражений
    vec3 fromCameraVec = self.modelPos - cameraObj.cameraPos;
    float lengthVal = length(fromCameraVec);
    mat4 lengthCorrection = scale(mat4(1.0), vec3(1.0) + vec3(lengthVal)/GlobI.worldSize);
    
    // включаем шейдер для отрисовки
    [StatesI useProgramm:ShadI.skyModelShaderProgram];

    // помещаем матрицу модельвидпроекция в шейдер (указываем)
    [StatesI setUniformMat4:_modelMatrixLocation val:modelMat];
    [StatesI setUniformMat4:_viewMatrixLocation val:camera];
    [StatesI setUniformMat4:_projMatrixLocation val:projection];
    [StatesI setUniformMat4:_lengthCorrectionLocation val:lengthCorrection];
    [StatesI setUniformVec3:_cameraPosLocation val:glSpaceCameraPos];

    if (toShadowMap == FALSE) {
        // текстура
        [StatesI setUniformInt:_modelTextureLocation val:0];
        [StatesI activateTexture:GL_TEXTURE0 type:GL_TEXTURE_2D texId:_modelTexture];
        
        // текстура нормалей
        [StatesI setUniformInt:_normalsTextureLocation val:1];
        [StatesI activateTexture:GL_TEXTURE1 type:GL_TEXTURE_2D texId:_normalsTexture];
        
        // текстура куба
        [StatesI setUniformInt:_modelCubemapTextureLocation val:2];
        [StatesI activateTexture:GL_TEXTURE2 type:GL_TEXTURE_CUBE_MAP texId:self.boxTexture];
    }


    // включаем объект аттрибутов вершин
    [StatesI bindVAO:_modelVAO];
    if (_modelElementsCount > 0) {
        glDrawElements(GL_TRIANGLES, _modelElementsCount, _modelElementsType, 0);
    }
}

-(void)dealloc{
    destroyVAO(_modelVAO);
    // TODO: удаление текстур
    [super dealloc];
}

@end