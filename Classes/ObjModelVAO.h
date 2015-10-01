//
//  ObjModel.h
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 10.04.15.
//
//

#import <Foundation/Foundation.h>
#import "glUtil.h"
#import "glm.hpp"
#import "ext.hpp"
#import <vector>
#import "GlobalValues.h"

using namespace std;

struct Buffer{
    uint bufferId;
    size_t bufferSize;
    Buffer(){
        bufferId = -1;
        bufferSize = 0;
    }
    Buffer(uint buffId, size_t size){
        bufferId = buffId;
        bufferSize = size;
    }
};

GLuint buildObjVAO(NSString* filename, uint *elementsCount);
GLuint buildObjVAO(NSString* filename, uint *elementsCount, BoudndingBox& box);
GLuint buildObjVAO(NSString* filename, uint *elementsCount, vector<Buffer>& buffers, BOOL withCache);
GLuint buildObjVAO(NSString* filename, uint *elementsCount, vector<Buffer>& buffers, BOOL withCache, BoudndingBox& box);
