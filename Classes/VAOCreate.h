//
//  VAOCreate.h
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 05.04.15.
//
//

#import <Foundation/Foundation.h>
#import "glUtil.h"
#import "modelUtil.h"
#import "GlobalValues.h"
#import <vector>

GLuint particlesVAO(int* pointsCount);
GLuint cubeVAO(int* elementsCount);
GLuint debugSpriteVAO(int* elementsCounter);
GLuint spriteVAO(int* elementsCounter);
GLuint skyboxVAO(int* elementsCounter);
GLuint buildModelVAO(GLuint* elementsCounter, GLuint* elementsType, BoudndingBox& box);
GLuint billboardVAO(std::vector<vec3> positions);

void destroyVAO(GLuint vaoName);