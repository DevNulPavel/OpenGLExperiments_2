//
//  RenderObject.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import <Foundation/Foundation.h>
#import "RenderObject.h"
#import "GlobalValues.h"

@implementation RenderObject

-(id)init{
    if ((self = [super init])) {
        [self setDefaultValues];
    }
    return self;
}

-(void)setDefaultValues{
    self.scale = 1.0;
    self.modelPos = vec3(0.0);
    self.rotateQuat = quat(vec3(0.0));
}

-(BOOL)isVisibleFromCamera:(Camera*)cameraObj{
    mat4 modelMat = [self modelTransformMatrix];
    mat4 camera = [cameraObj cameraMatrix];
    mat4 proj = [self projectionMatrix];
    mat4 mvp = proj * camera * modelMat;
    return [self isVisible:mvp];
}

-(BOOL)checkProjPos:(vec4)pos{
    if ((abs(pos.x) < pos.w) && (abs(pos.y) < pos.w) && (pos.z > 0) && (pos.z < pos.w)) {
        return TRUE;
    }
    return FALSE;
}

-(BOOL)isVisible:(const mat4&)mvp{
    vec4 pos;
    pos = mvp * vec4(self.boundBox.leftBotomNear, 1.0);
    if ([self checkProjPos:pos]) {
        return TRUE;
    }
    pos = mvp * vec4(self.boundBox.rightBotomNear, 1.0);
    if ([self checkProjPos:pos]) {
        return TRUE;
    }
    pos = mvp * vec4(self.boundBox.leftTopNear, 1.0);
    if ([self checkProjPos:pos]) {
        return TRUE;
    }
    pos = mvp * vec4(self.boundBox.rightTopNear, 1.0);
    if ([self checkProjPos:pos]) {
        return TRUE;
    }
    
    pos = mvp * vec4(self.boundBox.leftBotomFar, 1.0);
    if ([self checkProjPos:pos]) {
        return TRUE;
    }
    pos = mvp * vec4(self.boundBox.rightBotomFar, 1.0);
    if ([self checkProjPos:pos]) {
        return TRUE;
    }
    pos = mvp * vec4(self.boundBox.leftTopFar, 1.0);
    if ([self checkProjPos:pos]) {
        return TRUE;
    }
    pos = mvp * vec4(self.boundBox.rightTopFar, 1.0);
    if ([self checkProjPos:pos]) {
        return TRUE;
    }
    return FALSE;
}

-(void)renderModelFromCamera:(Camera*)cameraObj light:(LightObject*)light toShadow:(BOOL)toShadowMap customProj:(const mat4*)customProj {
}

-(mat4)modelTransformMatrix{
    mat4 modelMat;
    // обновляем матрицу модели (ОБРАТНЫЙ ПОРЯДОК)
    modelMat = translate(modelMat, self.modelPos);
    modelMat = modelMat * toMat4(self.rotateQuat);
    modelMat = scale(modelMat, vec3(self.scale));
    return modelMat;
}

-(mat4)projectionMatrix{
    mat4 projection = GlobI.projectionMatrix;
    return projection;
}

@end