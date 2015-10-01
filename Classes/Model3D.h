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
#import "btBulletCollisionCommon.h"
#import "btBulletDynamicsCommon.h"

using namespace glm;

@interface Model3D: RenderObject{
    // модель
    GLint _modelVAO;
    GLuint _modelElementsCount;
    GLuint _modelElementsType;
    
    // текстуры
    GLint _modelTexture;
    GLint _normalsTexture;
    
    // шейдер
    GLint _mvpMatrixLocation;
    GLint _mvMatrixLocation;
    GLint _projMatrixLocation;
    GLint _viewMatrixLocation;
    GLint _modelMatrixLocation;
    GLint _inShadowMatrixLocation;
    GLint _lightPosLocation;
    GLint _modelTextureLocation;
    GLint _shadowMapTextureLocation;
    GLint _normalsTextureLocation;
}

@property (nonatomic, assign) btRigidBody* body;
@property (nonatomic, assign) btCollisionShape* shape;

-(id)initWithObjFilename:(NSString *)filename withBody:(BOOL)withBody;
-(id)initWithFilename:(NSString *)filename;

-(void)addToPhysicsWorld;
-(void)setMass:(float)mass;
-(void)setVelocity:(vec3)velocity;

@end
