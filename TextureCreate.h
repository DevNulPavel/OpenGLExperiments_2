//
//  TextureCreate.h
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 05.04.15.
//
//

#import <Foundation/Foundation.h>
#import "glUtil.h"

GLuint buildSkyboxTexture();
GLuint buildTexture(NSString* name);
GLuint buildTextureWithExt(NSString* name, NSString* type);
GLuint buildEmpty2DTexture(GLuint internalFormat, GLuint format, uint width, uint height);
GLuint buildEmptyCubeTexture(GLuint internalFormat, GLuint format, uint width, uint height);
