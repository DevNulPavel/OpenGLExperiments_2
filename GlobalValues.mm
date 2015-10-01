//
//  GlobalValues.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "GlobalValues.h"



// random integer in [mn, mx)
int random_int(int mn, int mx) {
    int diff = mx - mn;
    if (diff != 0) {
        return mn + rand() % diff;
    }
    return mn;
}

float randomFloat(float mn, float mx) {
    float rnd = (float)rand() / RAND_MAX;
    rnd *= mx - mn;
    rnd += mn;
    return rnd;
}



static GlobalValues *instance = nil;

@implementation GlobalValues

+ (GlobalValues *)instance {
    @synchronized(self) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    }
    return instance;
}

-(id)init{
    if ((self = [super init])) {
        self.cameraInitPos = vec3(0.0, 0.0, 50.0);
        self.worldSize = vec3(100.0);
        self.zNear = 1.0f;
        self.zFar = 1000.0f;
        self.shadowMapScale = 2.0;
        self.viewHeight = 1;
        self.viewWidth = 1;
        
        self.lookTargetPos = vec3(0.0);
        
        mat4 sourceCubemapProjection = perspective(float(90.0/180.0*M_PI), 1.0f, self.zNear, self.zFar);
        for(int i = 0; i < 6; i++){
            // строки проективной матрицы
            const vec4& rX = sourceCubemapProjection[0];
            const vec4& rY = sourceCubemapProjection[1];
            const vec4& rZ = sourceCubemapProjection[2];
            const vec4& rW = sourceCubemapProjection[3];
            
            // переставляем хитрым образом и домножаем на матрицу перемещения в заданную точку
            _cubemapProjections[0] = mat4( -rZ, -rY, -rX, rW );//1
            _cubemapProjections[1] = mat4(  rZ, -rY,  rX, rW );//2
            _cubemapProjections[2] = mat4(  rX, -rZ,  rY, rW );//3
            _cubemapProjections[3] = mat4(  rX,  rZ, -rY, rW );//4
            _cubemapProjections[4] = mat4(  rX, -rY, -rZ, rW );//5
            _cubemapProjections[5] = mat4( -rX, -rY,  rZ, rW );//6
        }
        
        _initTime = [[NSDate date] timeIntervalSince1970];
        _lastRenderTime = _initTime;
    }
    return self;
}

-(const mat4&)cubemapProj:(int)index{
    return _cubemapProjections[index];
}

-(void)updateProjection{
    self.projectionMatrix = perspective(float(60.0/180.0*M_PI), float((float)self.viewWidth / (float)self.viewHeight), self.zNear, self.zFar);
}

-(void)setViewHeight:(float)viewHeight{
    _viewHeight = viewHeight;
    [self updateProjection];
}

-(void)setViewWidth:(float)viewWidth{
    _viewWidth = viewWidth;
    [self updateProjection];
}

-(float)timeFromStart{
    return [[NSDate date] timeIntervalSince1970] - _initTime;
}

-(float)angle{
    // полный оборот в 10 сек
    float time = 10.0;
    float angle = fmod([self timeFromStart] * M_PI * 2 / time, M_PI*2);;
    return angle;
}

-(float)deltaTime{
    return [[NSDate date] timeIntervalSince1970] - _lastRenderTime;
}

-(void)rendered{
    _lastRenderTime = [[NSDate date] timeIntervalSince1970];
}
@end