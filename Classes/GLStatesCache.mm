//
//  FontRender.m
//  OSXGLEssentials
//
//  Created by DevNul on 16.04.15.
//
//

#import "GLStatesCache.h"
#import "glUtil.h"

static GLStatesCache* statesInstance = nil;

@implementation GLStatesCache

+ (GLStatesCache*)instance {
    @synchronized(self) {
        if (statesInstance == nil) {
            statesInstance = [[self alloc] init];
        }
    }
    return statesInstance;
}

-(id)init{
    if ((self = [super init])) {
        _activeVao = -9999;
        _activeProgram = -9999;
    }
    return self;
}

-(void)enableState:(GLuint)state{
    if (_states[state] == FALSE) {
        _states[state] = TRUE;
        glEnable(state);
    }
}

-(void)disableState:(GLuint)state{
    if (_states[state] == TRUE) {
        _states[state] = FALSE;
        glDisable(state);
    }
}

-(BOOL)isEnabled:(GLuint)state{
    return _states[state];
}

-(void)bindVAO:(GLuint)vao{
    if (_activeVao != vao) {
        _activeVao = vao;
        glBindVertexArray(vao);
    }
}

-(void)activateTexture:(GLuint)texIndex type:(GLuint)texType texId:(GLuint)textureId{
    ActiveTextureInfo info = _activeTextures[texIndex];
    if (info.textureId != textureId || info.textureType != texType) {
        ActiveTextureInfo info;
        info.textureType = texType;
        info.textureId = textureId;
        
        _activeTextures[texIndex] = info;

        glActiveTexture(texIndex);
        glBindTexture(info.textureType, info.textureId);
    }
}

-(void)useProgramm:(GLint)program{
    if (_activeProgram != program) {
        // очищаем кеш состояний
        // акт программу
        _activeProgram = program;
        glUseProgram(program);
    }
}

-(void)setUniformInt:(GLint)location val:(const int&)val{
    if (_activeProgram >= 0 && location >= 0 && (_progsLocationStates[_activeProgram][location].intValue != val)) {
        _progsLocationStates[_activeProgram][location].intValue = val;
        glUniform1i(location, val);
    }
}
-(void)setUniformFloat:(GLint)location val:(const float&)val{
    if (_activeProgram >= 0 && location >= 0 && (_progsLocationStates[_activeProgram][location].floatValue != val)) {
        _progsLocationStates[_activeProgram][location].floatValue = val;
        glUniform1f(location, val);
    }
}

-(void)setUniformVec2:(GLint)location val:(const vec2&)val{
    if (_activeProgram >= 0 && location >= 0 && (_progsLocationStates[_activeProgram][location].vec2Value != val)) {
        _progsLocationStates[_activeProgram][location].vec2Value = val;
        glUniform2f(location, val.x, val.y);
    }
}

-(void)setUniformVec3:(GLint)location val:(const vec3&)val{
    if (_activeProgram >= 0 && location >= 0 && (_progsLocationStates[_activeProgram][location].vec3Value != val)) {
        _progsLocationStates[_activeProgram][location].vec3Value = val;
        glUniform3f(location, val.x, val.y, val.z);
    }
}

-(void)setUniformVec4:(GLint)location val:(const vec4&)val{
    if (_activeProgram >= 0 && location >= 0 && (_progsLocationStates[_activeProgram][location].vec4Value != val)) {
        _progsLocationStates[_activeProgram][location].vec4Value = val;
        glUniform4f(location, val.x, val.y, val.z, val.w);
    }
}

-(void)setUniformMat3:(GLint)location val:(const mat3&)val{
    if (_activeProgram >= 0 && location >= 0 && (_progsLocationStates[_activeProgram][location].mat3Value != val)) {
        _progsLocationStates[_activeProgram][location].mat3Value = val;
        glUniformMatrix3fv(location, 1, GL_FALSE, value_ptr(val));
    }
}

-(void)setUniformMat4:(GLint)location val:(const mat4&)val{
    if (_activeProgram >= 0 && location >= 0 && (_progsLocationStates[_activeProgram][location].mat4Value != val)) {
        _progsLocationStates[_activeProgram][location].mat4Value = val;
        glUniformMatrix4fv(location, 1, GL_FALSE, value_ptr(val));
    }
}

@end
