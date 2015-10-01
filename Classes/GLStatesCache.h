//
//  FontRender.h
//  OSXGLEssentials
//
//  Created by DevNul on 16.04.15.
//
//

#import <map>
#import <glm.hpp>
#import <ext.hpp>

using namespace std;
using namespace glm;

#define StatesI [GLStatesCache instance]

struct ActiveTextureInfo{
    GLint textureId;
    GLint textureType;
    ActiveTextureInfo(){
        textureId = -1;
        textureType = -1;
    }
};

struct ShaderLocationState{
    GLint intValue;
    GLfloat floatValue;
    vec2 vec2Value;
    vec3 vec3Value;
    vec4 vec4Value;
    mat3 mat3Value;
    mat4 mat4Value;
    ShaderLocationState(){
        intValue = -999;
        floatValue = -999;
        vec2Value = vec2(-999);
        vec3Value = vec3(-999);
        vec4Value = vec4(-999);
        mat3Value = mat3(-999);
        mat4Value = mat4(-999);
    }
};

typedef map<GLuint, ShaderLocationState> ProgramLocationStateMap;

@interface GLStatesCache : NSObject{
    map<GLuint, BOOL> _states;
    map<GLuint, ActiveTextureInfo> _activeTextures;
    GLint _activeVao;
    GLint _activeProgram;
    map<GLuint, ProgramLocationStateMap> _progsLocationStates;
}

+ (GLStatesCache*)instance;

-(void)enableState:(GLuint)state;
-(void)disableState:(GLuint)state;
-(BOOL)isEnabled:(GLuint)state;
-(void)bindVAO:(GLuint)vao;
-(void)activateTexture:(GLuint)texIndex type:(GLuint)texType texId:(GLuint)textureId;

-(void)useProgramm:(GLint)program;
-(void)setUniformInt:(GLint)location val:(const int&)val;
-(void)setUniformFloat:(GLint)location val:(const float&)val;
-(void)setUniformVec2:(GLint)location val:(const vec2&)val;
-(void)setUniformVec3:(GLint)location val:(const vec3&)val;
-(void)setUniformVec4:(GLint)location val:(const vec4&)val;
-(void)setUniformMat3:(GLint)location val:(const mat3&)val;
-(void)setUniformMat4:(GLint)location val:(const mat4&)val;

@end
