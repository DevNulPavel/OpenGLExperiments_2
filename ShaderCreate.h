//
//  ShaderCreate.h
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 05.04.15.
//
//

#import <Foundation/Foundation.h>
#import "glUtil.h"

GLuint makeShader(NSString* shaderName, NSDictionary* attributeIndexes);

GLuint buildSkyCharacter();
GLuint buildCubeProgram();
GLuint buildParticlesProgram();
GLuint buildProgramFunc();
GLuint buildSpriteProgram();
GLuint buildSkyboxProgram();
GLuint buildBillboardProgram();
GLuint buildHeightProgram();
GLuint buildHeightSpriteProgram();
GLuint buildTextProgram();
