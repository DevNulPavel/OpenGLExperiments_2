//
//  Model3D.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "ParticlesModel.h"
#import "GlobalValues.h"
#import "ObjModelVAO.h"
#import "VAOCreate.h"
#import "TextureCreate.h"
#import "ShadersCache.h"
#import "GlobalValues.h"
#import "GLStatesCache.h"

@implementation ParticlesModel

-(id)init{
    if ((self = [super init])) {
        _particlesVAO = particlesVAO(&_particlesPointsCount);
        
        [self generateShader];
        [self makeBoundBox];
    }
    return self;
}

-(void)setDefaultValues{
    self.modelPos = vec3(0.0);
}

-(void)generateShader{
    // частицы
    _particlesTimeLocation = glGetUniformLocation(ShadI.particlesShader, "u_time");
    _particlesMVPLocation = glGetUniformLocation(ShadI.particlesShader, "u_mvp");
}

-(void)makeBoundBox{
    vec3 minimum(-1.0);
    vec3 maximum(1.0);
    
    // баундинг бокс
    BoudndingBox box;
    box.leftBotomNear = vec3(minimum.x, minimum.y, minimum.z);
    box.rightBotomNear = vec3(maximum.x, minimum.y, minimum.z);
    box.leftTopNear = vec3(minimum.x, maximum.y, minimum.z);
    box.rightTopNear = vec3(maximum.x, maximum.y, minimum.z);
    
    box.leftBotomFar = vec3(minimum.x, minimum.y, maximum.z);
    box.rightBotomFar = vec3(maximum.x, minimum.y, maximum.z);
    box.leftTopFar = vec3(minimum.x, maximum.y, maximum.z);
    box.rightTopFar = vec3(maximum.x, maximum.y, maximum.z);
    
    self.boundBox = box;
}

-(void)renderModelFromCamera:(Camera*)cameraObj light:(LightObject*)light toShadow:(BOOL)toShadowMap customProj:(const mat4*)customProj{
    // обновляем матрицу модели (ОБРАТНЫЙ ПОРЯДОК)
    mat4 model = [self modelTransformMatrix];
    
    // камера вида
    mat4 camera;
    if (toShadowMap == FALSE) {
        camera = [cameraObj cameraMatrix];
    }else{
        camera = lookAt(light.lightPos, light.lightTargetPos, vec3(0.0, 1.0, 0.0));
    }
    
    // проекция
    mat4 projection;
    if (customProj) {
        projection = *customProj;
    }else{
        projection = [self projectionMatrix];
    }
    
    // умножаем матрицу проекции на вью на матрицу модели и получаем матрицу для домножения на точку
    mat4 mvp = projection * camera * model;
    
    if ([self isVisible:mvp] == FALSE) {
        return;
    }
    
    [StatesI useProgramm:ShadI.particlesShader];
    
    float time = [GlobI timeFromStart];
    [StatesI setUniformFloat:_particlesTimeLocation val:time];
    
    [StatesI setUniformMat4:_particlesMVPLocation val:mvp];
    
    [StatesI enableState:GL_POINT_SIZE];
    [StatesI enableState:GL_VERTEX_PROGRAM_POINT_SIZE];
    
    [StatesI bindVAO:_particlesVAO];
    glDrawArrays(GL_POINTS, 0, _particlesPointsCount);
}

-(void)dealloc{
    destroyVAO(_particlesVAO);
    // TODO: удаление текстур
    [super dealloc];
}

@end