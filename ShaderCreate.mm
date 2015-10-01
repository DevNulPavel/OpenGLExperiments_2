//
//  ShaderCreate.m
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 05.04.15.
//
//

#import "ShaderCreate.h"
#import "sourceUtil.h"


GLuint makeShader(NSString* shaderName, NSDictionary* attributeIndexes){
    NSString* filePathName = nil;
    
    demoSource* vertexSource = NULL;
    demoSource* geometrySource = NULL;
    demoSource* fragmentSource = NULL;
    
    filePathName = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"vsh"];
    if (filePathName) {
        vertexSource = srcLoadSource([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
    }
    filePathName = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"gsh"];
    if (filePathName) {
        geometrySource = srcLoadSource([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
    }
    filePathName = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"fsh"];
    if (filePathName) {
        fragmentSource = srcLoadSource([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
    }
    
    GLuint prgName;
    GLint logLength, status;
    
    // строка
    GLchar* sourceString = NULL;
    
    // определяем версию языка, которая доступна
    float  glLanguageVersion;
    
    sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &glLanguageVersion);
    
    GLuint version = 100 * glLanguageVersion;
    
    // Get the size of the version preprocessor string info so we know
    //  how much memory to allocate for our sourceString
    const GLsizei versionStringSize = sizeof("#version 123\n");
    
    // создание объекта программы
    prgName = glCreateProgram();
    
    // задаем соответствие названия в шейдере и аттрибутов вершин
    for (NSString* indexStr in attributeIndexes.allKeys) {
        int index = [indexStr intValue];
        NSString* name = [attributeIndexes objectForKey:indexStr];
        glBindAttribLocation(prgName, index, [name cStringUsingEncoding:NSASCIIStringEncoding]);
    }
    // для вывода в слои
    glBindFragDataLocation(prgName, 0, "fragColor");
    glBindFragDataLocation(prgName, 1, "fragColor2");
    glBindFragDataLocation(prgName, 2, "fragColor3");
    
    
    /////////////////////////////////
    // создание вершинного шейдера //
    /////////////////////////////////
    if (vertexSource) {
        // выделяем память под строку версии шейдера
        sourceString = (GLchar*)malloc(vertexSource->byteSize + versionStringSize);
        
        // добавляем версию к шейдеру
        sprintf(sourceString, "#version %d\n%s", version, vertexSource->string);
        
        // создаем вершинный шейдер
        GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vertexShader, 1, (const GLchar **)&(sourceString), NULL);
        glCompileShader(vertexShader);
        glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);
        
        // инфа
        if (logLength > 0) {
            GLchar *log = (GLchar*) malloc(logLength);
            glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
            NSLog(@"Vtx Shader compile log:%s\n", log);
            free(log);
        }
        
        // лог компиляции
        glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &status);
        if (status == 0) {
            NSLog(@"Failed to compile vtx shader:\n%s\n", sourceString);
            return 0;
        }
        
        free(sourceString);
        sourceString = NULL;
        
        // подсоединяем вершинный шейдер к обхекту программы
        glAttachShader(prgName, vertexShader);
        
        // удаляем шейдер, тк он уже присоединен к программе
        glDeleteShader(vertexShader);
        
        srcDestroySource(vertexSource);
    }
    
    /////////////////////////////////////////
    // создание геометрического шейдера ////
    ////////////////////////////////////////
    
    if (geometrySource) {
        // выделяем память под строку версии шейдера
        sourceString = (GLchar*)malloc(geometrySource->byteSize + versionStringSize);
        
        // добавляем версию к шейдеру
        sprintf(sourceString, "#version %d\n%s", version, geometrySource->string);
        
        // создаем вершинный шейдер
        GLuint geometryShader = glCreateShader(GL_GEOMETRY_SHADER);
        glShaderSource(geometryShader, 1, (const GLchar **)&(sourceString), NULL);
        glCompileShader(geometryShader);
        glGetShaderiv(geometryShader, GL_INFO_LOG_LENGTH, &logLength);
        
        // инфа
        if (logLength > 0) {
            GLchar *log = (GLchar*) malloc(logLength);
            glGetShaderInfoLog(geometryShader, logLength, &logLength, log);
            NSLog(@"Vtx Shader compile log:%s\n", log);
            free(log);
        }
        
        // лог компиляции
        glGetShaderiv(geometryShader, GL_COMPILE_STATUS, &status);
        if (status == 0) {
            NSLog(@"Failed to compile geom shader:\n%s\n", sourceString);
            return 0;
        }
        
        free(sourceString);
        sourceString = NULL;
        
        // подсоединяем вершинный шейдер к обхекту программы
        glAttachShader(prgName, geometryShader);
        
        // удаляем шейдер, тк он уже присоединен к программе
        glDeleteShader(geometryShader);
        
        srcDestroySource(geometrySource);
    }
    
    ////////////////////////
    // фрагментный шейдер //
    ////////////////////////
    
    if (fragmentSource) {
        // выделяем память под версию
        sourceString = (GLchar*)malloc(fragmentSource->byteSize + versionStringSize);
        
        // добавляем версию в текст
        sprintf(sourceString, "#version %d\n%s", version, fragmentSource->string);
        
        // фрагментный шейдер
        GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fragShader, 1, (const GLchar **)&(sourceString), NULL);
        glCompileShader(fragShader);
        glGetShaderiv(fragShader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar*)malloc(logLength);
            glGetShaderInfoLog(fragShader, logLength, &logLength, log);
            NSLog(@"Frag Shader compile log:\n%s\n", log);
            free(log);
        }
        
        glGetShaderiv(fragShader, GL_COMPILE_STATUS, &status);
        if (status == 0) {
            NSLog(@"Failed to compile frag shader:\n%s\n", sourceString);
            return 0;
        }
        
        free(sourceString);
        sourceString = NULL;
        
        // присоединяем фрагментный к программе
        glAttachShader(prgName, fragShader);
        
        // удаляем, тк присоединен
        glDeleteShader(fragShader);
        
        srcDestroySource(fragmentSource);
    }
    
    //////////////////////
    // сборка программы //
    //////////////////////
    
    glLinkProgram(prgName);
    glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0){
        GLchar *log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(prgName, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s\n", log);
        free(log);
    }
    
    glGetProgramiv(prgName, GL_LINK_STATUS, &status);
    if (status == 0){
        NSLog(@"Failed to link program");
        return 0;
    }
    
    // проверка на валидность
    glValidateProgram(prgName);
    glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar*)malloc(logLength);
        glGetProgramInfoLog(prgName, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s\n", log);
        free(log);
    }
    
    glGetProgramiv(prgName, GL_VALIDATE_STATUS, &status);
    if (status == 0){
        NSLog(@"Failed to validate program");
    }
    
    // включаем данную программу
    glUseProgram(0);
    
    GetGLError();
    
    return prgName;
}

GLuint buildSkyCharacter(){
    GLuint progr = makeShader(@"skycharacter", @{@(0): @"inPosition",
                                                 @(1): @"inNormal",
                                                 @(2): @"inTexcoord",
                                                 @(3): @"inTangent",});
    return progr;
}

GLuint buildCubeProgram(){
    GLuint progr = makeShader(@"cube", @{@(0): @"inPosition",
                                         @(1): @"inColor",});
    return progr;
}

GLuint buildParticlesProgram(){
    GLuint progr = makeShader(@"particles", @{@(0): @"inPosition"});
    return progr;
}

GLuint buildProgramFunc(){
    GLuint progr = makeShader(@"character", @{@(0): @"inPosition",
                                              @(1): @"inNormal",
                                              @(2): @"inTexcoord",
                                              @(3): @"inTangent",});
    return progr;
}

GLuint buildSpriteProgram(){
    GLuint progr = makeShader(@"sprite", @{@(0): @"inPosition",
                                           @(1): @"inTexCoord"});
    return progr;
}

GLuint buildSkyboxProgram(){
    GLuint progr = makeShader(@"skybox", @{@(0):@"inPosition"});
    return progr;
}

GLuint buildBillboardProgram(){
    GLuint progr = makeShader(@"billboard", @{@(0):@"inPosition"});
    return progr;
}

GLuint buildHeightProgram(){
    GLuint progr = makeShader(@"height", @{@(0):@"inPosition",
                                           @(1):@"inNormal",
                                           @(2):@"inTexcoord"});
    return progr;
}

GLuint buildHeightSpriteProgram(){
    GLuint progr = makeShader(@"heightSprite", @{@(0):@"inPosition",
                                                 @(1):@"inTexCoord"});
    return progr;
}

GLuint buildTextProgram(){
    GLuint progr = makeShader(@"text", @{@(0): @"inPosition",
                                         @(1): @"inTexCoord"});
    return progr;
}
