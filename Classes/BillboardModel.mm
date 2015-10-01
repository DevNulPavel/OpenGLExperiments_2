//
//  Model3D.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "BillboardModel.h"
#import "GlobalValues.h"
#import "ObjModelVAO.h"
#import "VAOCreate.h"
#import "TextureCreate.h"
#import "ShadersCache.h"
#import "GlobalValues.h"
#import "GLStatesCache.h"

@implementation BillboardModel

-(id)initWithPositions:(std::vector<vec3>) positions{
    if ((self = [super init])) {
        _billboardPointVAO = billboardVAO(positions);    // создается толкьо одна точка, но можно сколько угодно для частиц
        _billboardPointCount = positions.size();
        _billboardTexture = buildTexture(@"bush");
        
        [self generateShader];
    }
    return self;
}

-(id)initOne{
    if ((self = [super init])) {
        std::vector<vec3> vector;
        vector.push_back(vec3(0.0));
        _billboardPointVAO = billboardVAO(vector);    // создается толкьо одна точка, но можно сколько угодно для частиц
        _billboardPointCount = 1;
        _billboardTexture = buildTexture(@"bush");
        
        [self generateShader];
    }
    return self;
}

-(void)generateShader{
    // билборд
    _billboardModelLocation = glGetUniformLocation(ShadI.billboardShaderProgram, "u_model");
    _billboardViewlLocation = glGetUniformLocation(ShadI.billboardShaderProgram, "u_view");
    _billboardProjLocation = glGetUniformLocation(ShadI.billboardShaderProgram, "u_proj");
    _billboardTextureLocation = glGetUniformLocation(ShadI.billboardShaderProgram, "u_texture");
    _billboardCameraPosLocation = glGetUniformLocation(ShadI.billboardShaderProgram, "u_cameraPosWorld");
}

-(void)renderModelFromCamera:(Camera*)cameraObj light:(LightObject*)light toShadow:(BOOL)toShadowMap customProj:(const mat4*)customProj{
    if (toShadowMap) {
        return;
    }
    
    mat4 model = [self modelTransformMatrix];
    mat4 camera = [cameraObj cameraMatrix];
    mat4 projection = [self projectionMatrix];
    
    [StatesI useProgramm:ShadI.billboardShaderProgram];
    
    // матрица
    [StatesI setUniformMat4:_billboardModelLocation val:model];
    [StatesI setUniformMat4:_billboardViewlLocation val:camera];
    [StatesI setUniformMat4:_billboardProjLocation val:projection];
    [StatesI setUniformVec3:_billboardCameraPosLocation val:cameraObj.cameraPos];

    // текстура
    [StatesI setUniformInt:_billboardTextureLocation val:0];
    [StatesI activateTexture:GL_TEXTURE0 type:GL_TEXTURE_2D texId:_billboardTexture];
    
    [StatesI bindVAO:_billboardPointVAO];
    glDrawArrays(GL_POINTS, 0, _billboardPointCount);
}

-(void)dealloc{
    destroyVAO(_billboardPointVAO);
    // TODO: удаление текстур
    [super dealloc];
}

@end