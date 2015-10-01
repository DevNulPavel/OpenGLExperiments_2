//
//  ObjModel.m
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 10.04.15.
//
//

#import "ObjModelPhysShape.h"
#import "glm.hpp"
#import "ext.hpp"
#import <map>
#import <vector>
#import <string>
#import "ObjFileClass.h"

using namespace glm;

std::map<std::string, btConvexHullShape*> objShapeCache;

btConvexHullShape* buildObjShape(NSString* filename){
    const char* cstrName = [filename cStringUsingEncoding:NSASCIIStringEncoding];
    std::string key(cstrName);
//     отключено кеширование
//    if (objShapeCache[key] != nil) {
//        return objShapeCache[key];
//    }
    
    NSString* filePathName = [[NSBundle mainBundle] pathForResource:filename ofType:@"obj"];
    Model model([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
    
    btConvexHullShape* shape = new btConvexHullShape();
    for (int i = 0; i < model.vertsCount(); i++) {
        vec4 vertex = model.vert(i);
        btVector3 bv = btVector3(vertex.x, vertex.y, vertex.z);
        shape->addPoint(bv);
    }
    
    objShapeCache[key] = shape;
    
    return shape;
}


