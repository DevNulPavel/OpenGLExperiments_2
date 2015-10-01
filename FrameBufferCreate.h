//
//  FrameBufferCreate.h
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 05.04.15.
//
//

#import <Foundation/Foundation.h>
#include "glUtil.h"


GLuint createHeightFBO(uint width, uint height, uint& pixelBufferSize, uint& pixelBufferVertex, uint& pixelBufferNormal, uint& pixelBufferTexCoord);
GLuint buildShadowFBO(int viewWidth, int viewHeight, GLuint* depthTexture);
GLuint buildCubeFBO(GLuint* colorTexture, uint width, uint height);
void destroyFBO(GLuint fboName);
