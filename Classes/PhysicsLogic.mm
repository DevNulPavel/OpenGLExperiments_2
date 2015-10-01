//
//  PhysicsLogic.m
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 11.04.15.
//
//

#import "PhysicsLogic.h"
#import "GlobalValues.h"


static PhysicsLogic* physicsInstance = nil;

@implementation PhysicsLogic

+ (PhysicsLogic *)instance {
    @synchronized(self) {
        if (physicsInstance == nil) {
            physicsInstance = [[self alloc] init];
        }
    }
    return physicsInstance;
}

-(id)init{
    if ((self = [super init])) {
        //1
        _broadphase = new btDbvtBroadphase();
        
        //2
        _collisionConfiguration = new btDefaultCollisionConfiguration();
        _dispatcher = new btCollisionDispatcher(_collisionConfiguration);
        
        //3
        _solver = new btSequentialImpulseConstraintSolver();
        
        //4
        _world = new btDiscreteDynamicsWorld(_dispatcher, _broadphase, _solver, _collisionConfiguration);
        
        //5
        _world->setGravity(btVector3(0, -9.8*40.0, 0));
//        _world->setGravity(btVector3(0, 0.0, 0));
        
        [self makeGround];
    }
    return self;
}

-(void)makeGround{
    btStaticPlaneShape* shape = new btStaticPlaneShape(btVector3(0, 1, 0), GlobI.worldSize.y/2);
    
    btQuaternion rotation;
    rotation.setEulerZYX(0, 0, 0);
    btVector3 position = btVector3(0, -GlobI.worldSize.y, 0);
    
    // движение
    btDefaultMotionState* motionState = new btDefaultMotionState(btTransform(rotation, position));
    
    // масса и инерция
    btScalar bodyMass = 0.0;
    btVector3 bodyInertia;
    shape->calculateLocalInertia(bodyMass, bodyInertia);
    
    //5
    btRigidBody::btRigidBodyConstructionInfo bodyCI = btRigidBody::btRigidBodyConstructionInfo(bodyMass, motionState, shape, bodyInertia);
    
    //6
    bodyCI.m_restitution = 0.8f;    // сила отскока 0 - нету, 0-1 - с затуханием, >1 - с усилением
    bodyCI.m_friction = 0.5f;       // поворот при отскоке ??
    
    btRigidBody* body = new btRigidBody(bodyCI);
    body->setUserPointer((__bridge void*)self);
    body->setLinearFactor(btVector3(1, 1, 1));
    
    _world->addRigidBody(body);
}

-(void)dealloc{
    delete _broadphase;
    delete _collisionConfiguration;
    delete _dispatcher;
    delete _solver;
    delete _world;
    
    [super dealloc];
}

@end
