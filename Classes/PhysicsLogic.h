//
//  PhysicsLogic.h
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 11.04.15.
//
//

#import <Foundation/Foundation.h>
#import "btBulletCollisionCommon.h"
#import "btBulletDynamicsCommon.h"

#define PhysI [PhysicsLogic instance]

@interface PhysicsLogic : NSObject{
}

+ (PhysicsLogic *)instance;

@property (nonatomic, assign) btBroadphaseInterface* broadphase;
@property (nonatomic, assign) btDefaultCollisionConfiguration* collisionConfiguration;
@property (nonatomic, assign) btCollisionDispatcher* dispatcher;
@property (nonatomic, assign) btSequentialImpulseConstraintSolver* solver;
@property (nonatomic, assign) btDiscreteDynamicsWorld* world;

@end
