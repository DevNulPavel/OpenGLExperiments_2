//
//  ObjModel.h
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 10.04.15.
//
//

#import <Foundation/Foundation.h>
#import "btBulletCollisionCommon.h"
#import "btBulletDynamicsCommon.h"


btConvexHullShape* buildObjShape(NSString* filename);
