//
//  Camera.m
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 06.04.15.
//
//

#import "Camera.h"
#import "PhysicsLogic.h"

#define X_MOUSE_STEP 0.002f
#define Y_MOUSE_STEP 0.002f
#define KEY_STEP 25.0f


@implementation Camera

-(id)initWithCameraPos:(vec3)cameraPos{
    if ((self = [super init])) {
        _cameraPos = cameraPos;
        _cameraUp = vec3(0.0, 1.0, 0.0);
        _horisontalAngle = M_PI/2;
        _verticalAngle = 0.0;
        
        [self update];
        [self createPhysicsShape];
        [self addToPhysicsWorld];
    }
    
    return self;
}

-(void)dealloc{
    delete self.shape;
    
    [super dealloc];
}

-(void)mouseMoved:(float)deltaX deltaY:(float)deltaY{
    _horisontalAngle -= deltaX * X_MOUSE_STEP;
    _verticalAngle += deltaY * Y_MOUSE_STEP;
    
    if (_verticalAngle > M_PI/2.0 - 0.001) {
        _verticalAngle = M_PI/2.0 - 0.001;
    }
    if (_verticalAngle < -M_PI/2.0 + 0.001) {
        _verticalAngle = -M_PI/2.0 + 0.001;
    }
}

-(void)keyButtonUp:(NSString*)chars{
    for (int i = 0; i < chars.length; i++) {
        unichar symbol = [chars characterAtIndex:i];
        _activeButtonsMap[symbol] = FALSE;
    }
}

-(void)keyButtonDown:(NSString*)chars{
    for (int i = 0; i < chars.length; i++) {
        unichar symbol = [chars characterAtIndex:i];
        _activeButtonsMap[symbol] = TRUE;
    }
}

-(void)handleKeys{
    for (map<unichar, BOOL>::const_iterator i = _activeButtonsMap.begin(); i != _activeButtonsMap.end(); i++) {
        unichar symbol = i->first;
        BOOL isActive = i->second;

        if (isActive) {
            float timeDelta = [self timeDelta];
            
            switch (symbol) {
                case 'a':{
                    // по правилу левой руки (указательный вверх 1, средний к цели 2 = большой направо)
                    vec3 rightDir = normalize(cross(_cameraUp, _cameraTarget));
                    _cameraPos += rightDir * KEY_STEP * timeDelta;
                }break;
                case 'd':{
                    // по правилу левой руки (указательный к цели 1, средний вверх 2 = большой налево)
                    vec3 leftDir = normalize(cross(_cameraTarget, _cameraUp));
                    _cameraPos += leftDir * KEY_STEP * timeDelta;
                }break;
                case 'w':{
                    _cameraPos += _cameraTarget * KEY_STEP * timeDelta;
                }break;
                case 's':{
                    _cameraPos -= _cameraTarget * KEY_STEP * timeDelta;
                }break;
                case 'e':{
                    _cameraPos += vec3(0.0, 1.0, 0.0)* KEY_STEP * timeDelta;
                }break;
                case 'q':{
                    _cameraPos -= vec3(0.0, 1.0, 0.0)* KEY_STEP * timeDelta;
                }break;
            }
        }
    }
}

-(void)updateTransforms{
    vec3 target(1.0f, 0.0f, 0.0f);
    // поворачиваем вектор, который направлен направо по оси y
    vec3 verticalAxis(0.0f, 1.0f, 0.0f);
    // поворачиваем по оси y
    target = normalize(rotate(target, _horisontalAngle, verticalAxis));
    //  вычисляем вычисляем горизонтальное направление после поворота
    vec3 horisontalAxis = normalize(cross(verticalAxis, target));
    // смотрим вверх-вниз
    _cameraTarget = rotate(target, _verticalAngle, horisontalAxis);
    // вычисляем направление "вверх"
    _cameraUp = normalize(cross(target, horisontalAxis));
}

-(void)update{
    [self handleKeys];
    [self updateTransforms];
    _lastUpdateTime = [NSDate timeIntervalSinceReferenceDate];
}

-(double)timeDelta{
    if (_lastUpdateTime == 0) {
        return 0;
    }
    return MAX([NSDate timeIntervalSinceReferenceDate] - _lastUpdateTime, 0.0);
}

-(vec3)cameraPos{
    return _cameraPos;
}

-(vec3)cameraTargetVec{
    return _cameraTarget;
}

-(vec3)cameraUp{
    return _cameraUp;
}

-(float)horisontalAngle{
    return _horisontalAngle;
}

-(float)verticalAngle{
    return _verticalAngle;
}

-(void)setCameraPos:(const vec3&)pos{
    _cameraPos = pos;
}

-(mat4)cameraMatrix{
    [self update];
    mat4 camera = lookAt(_cameraPos, _cameraPos + _cameraTarget, _cameraUp);
    return camera;
}

#pragma mark - Physics

-(void)createPhysicsShape{
    self.shape = new btCapsuleShape(3.0, 5.0);
    
    // углы поворота через zyx
    btQuaternion rotation;
    rotation.setEulerZYX(0.0, _horisontalAngle, _verticalAngle);
    
    // позиция фигуры
    btVector3 position = btVector3(_cameraPos.x, _cameraPos.y, _cameraPos.z);
    
    // движение
    btDefaultMotionState* motionState = new btDefaultMotionState(btTransform(rotation, position));
    
    // масса и инерция
    btScalar bodyMass = 0.0;
    btVector3 bodyInertia;
    self.shape->calculateLocalInertia(bodyMass, bodyInertia);
    
    //5
    btRigidBody::btRigidBodyConstructionInfo bodyCI = btRigidBody::btRigidBodyConstructionInfo(bodyMass, motionState, self.shape, bodyInertia);
    
    //6
    bodyCI.m_restitution = 1.0f;    // сила отскока 0 - нету, 0-1 - с затуханием, >1 - с усилением
    bodyCI.m_friction = 0.5f;       // поворот при отскоке ??
    
    //7
    self.body = new btRigidBody(bodyCI);
    
    //8
    self.body->setUserPointer((__bridge void*)self);
    
    //9
    self.body->setLinearFactor(btVector3(1, 1, 1));
}

-(void)addToPhysicsWorld{
    PhysI.world->addRigidBody(self.body);
}

-(void)updatePhysBody{
    if (self.body) {
        btTransform trans = self.body->getWorldTransform();
        // позиция
        trans.setOrigin(btVector3(_cameraPos.x, _cameraPos.y, _cameraPos.z));
        // поворот
        btQuaternion rotation;
        rotation.setEulerZYX(0.0, _horisontalAngle, _verticalAngle);
        trans.setRotation(rotation);
        self.body->setWorldTransform(trans);
    }
}

@end




@implementation CameraContainer
-(void)setCameraUp:(const vec3&)up{
    _cameraUp = up;
}
-(void)setCameraPos:(const vec3&)pos{
    _cameraPos = pos;
}
-(void)setCameraTarget:(const vec3&)pos{
    _cameraTarget = pos;
}
-(mat4)cameraMatrix{
    mat4 camera = lookAt(_cameraPos, _cameraPos + _cameraTarget, _cameraUp);
    return camera;
}
@end
