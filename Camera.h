//
//  Camera.h
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 06.04.15.
//
//

#import <Foundation/Foundation.h>
#import "glm.hpp"
#import "ext.hpp"
#import "btBulletCollisionCommon.h"
#import "btBulletDynamicsCommon.h"
#import <map>

using namespace glm;
using namespace std;

@interface Camera : NSObject{
    vec3 _cameraPos;
    vec3 _cameraTarget;
    vec3 _cameraUp;
    float _horisontalAngle;
    float _verticalAngle;
    map<unichar, BOOL> _activeButtonsMap;
    double _lastUpdateTime;
}

@property (nonatomic, assign) btRigidBody* body;
@property (nonatomic, assign) btCollisionShape* shape;

-(id)initWithCameraPos:(vec3)cameraPos;
-(void)mouseMoved:(float)deltaX deltaY:(float)deltaY;
-(void)keyButtonDown:(NSString*)chars;
-(void)keyButtonUp:(NSString*)chars;

-(void)update;

-(vec3)cameraTargetVec;
-(vec3)cameraUp;
-(vec3)cameraPos;
-(mat4)cameraMatrix;
-(float)horisontalAngle;
-(float)verticalAngle;
-(void)setCameraPos:(const vec3&)pos;

@end


@interface CameraContainer: Camera
-(void)setCameraPos:(const vec3&)pos;
-(void)setCameraUp:(const vec3&)up;
-(void)setCameraTarget:(const vec3&)pos;
@end