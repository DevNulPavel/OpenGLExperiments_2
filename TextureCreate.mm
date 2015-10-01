//
//  TextureCreate.m
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 05.04.15.
//
//

#import "TextureCreate.h"
#import "imageUtil.h"
#import "sourceUtil.h"

NSMutableDictionary* textureCache = [[NSMutableDictionary alloc] init];

// создание объекта текстуры
GLuint buildTextureWithExt(NSString* name, NSString* type) {
    NSString* filePathName = [[NSBundle mainBundle] pathForResource:name ofType:type];
    if (filePathName == nil) {
        return -1;
    }
    
    if ([textureCache objectForKey:name]) {
        int textId = [[textureCache objectForKey:name] intValue];
        return textId;
    }
    
    demoImage *image = imgLoadImage([filePathName cStringUsingEncoding:NSASCIIStringEncoding], false);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    
    // Indicate that pixel rows are tightly packed
    //  (defaults to stride of 4 which is kind of only good for
    //  RGBA or FLOAT data types)
//    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    glTexImage2D(GL_TEXTURE_2D, 0, image->format, image->width, image->height, 0, image->format, image->type, image->data);
    
    glGenerateMipmap(GL_TEXTURE_2D);
    
    GetGLError();
    
    imgDestroyImage(image);
    
    [textureCache setObject:@(texName) forKey:name];
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    return texName;
}

GLuint buildSkyboxTexture(){
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_CUBE_MAP, texName);  // кубическая текстура
    
    NSArray* names = @[@"sp3back",
                       @"sp3front",
                       @"sp3bot",
                       @"sp3top",
                       @"sp3left",
                       @"sp3right",];
    NSArray* types = @[@(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z),
                       @(GL_TEXTURE_CUBE_MAP_POSITIVE_Z),
                       @(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y),
                       @(GL_TEXTURE_CUBE_MAP_POSITIVE_Y),
                       @(GL_TEXTURE_CUBE_MAP_NEGATIVE_X),
                       @(GL_TEXTURE_CUBE_MAP_POSITIVE_X),];
    for (int i = 0; i < names.count; i++) {
        NSString* name = names[i];
        NSString* filePathName = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
        demoImage *image = imgLoadImage([filePathName cStringUsingEncoding:NSASCIIStringEncoding], false);
        
        glTexImage2D([types[i] intValue], 0, image->format, image->width, image->height, 0, image->format, image->type, image->data);
        
        imgDestroyImage(image);
    }
    
    glTexParameterf(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    
    glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
    
    return texName;
}

GLuint buildEmpty2DTexture(GLuint internalFormat, GLuint format, uint width, uint height){
    uint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, GL_FLOAT, 0);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    return texture;
}

// GL_RGB, GL_DEPTH_COMPONENT
GLuint buildEmptyCubeTexture(GLuint internalFormat, GLuint format, uint width, uint height){
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_CUBE_MAP, texName);  // кубическая текстура
    
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
    
    for (int i = 0; i < 6; i++) {
        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, internalFormat, width, height, 0, format, GL_FLOAT, 0);
    }
    
    return texName;
}


GLuint buildTexture(NSString* name){
    return buildTextureWithExt(name, @"png");
}