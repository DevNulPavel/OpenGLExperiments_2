//
//  Model3D.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "HeightMap.h"
#import "GlobalValues.h"
#import "ObjModelVAO.h"
#import "TextureCreate.h"
#import "ShadersCache.h"
#import "GlobalValues.h"
#import "GLStatesCache.h"
#import "FrameBufferCreate.h"
#import "VAOCreate.h"


@implementation HeightMap

-(id)init{
    if ((self = [super init])) {
        _height = 512;
        _width = 512;

        _heightTexture = buildTexture(@"heightMap");
        _modelTexture = buildTexture(@"heightMap");
        
        [self buildHeightFBO];
        [self preparePixelBuffers];
        [self prepareRenderingVAO];
        [self generateShader];
    }
    return self;
}

#pragma mark - Model

-(void)drawScreenQuad{
    int elementsCount = 0;
    uint spriteVao = spriteVAO(&elementsCount);
    [StatesI bindVAO:spriteVao];
    glDrawElements(GL_TRIANGLES, elementsCount, GL_UNSIGNED_INT, 0);
    destroyVAO(spriteVao);
}

-(void)buildHeightFBO{
    // создание буффера кадра в который можно отрендерить картинки
    _fbo = createHeightFBO(_height, _width, _pixelBuffersSize, _vertexPixelBuffer, _normalsPixelBuffer, _texcoordPixelBuffer);
}

-(void)preparePixelBuffers{
    // узнаем текущий вьюпорт для того, чтобы потом его восстановить
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    
    // задаем текущий вьюпорт размером с текстуру
    glViewport(0, 0, _width, _height);
    
    // активируем фрейм буффер и буфферы отрисовки
    glBindFramebuffer(GL_FRAMEBUFFER, _fbo);
    uint buffers[] = {GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2};
    glDrawBuffers(3, buffers);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // включаем шейдер, который рендерит в буфферы цвета вершинные аттрибуты
    uint program = ShadI.heightSpriteProgram;
    glUseProgram(program);
    glUniform1i(glGetUniformLocation(program, "u_heightMap"), 0);
    glUniform1f(glGetUniformLocation(program, "u_scaleFactor"), 0.2);
    glUniform1f(glGetUniformLocation(program, "u_invTexSize"), 1.0/_width);

    // текстура с инфой для высот
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _heightTexture);
    
    // рисуем на основании данных в фреймбуффер
    [self drawScreenQuad];
    glUseProgram(0);
    
    // читаем данные из буфферов в буфферы пикселей
    // вершины
    glReadBuffer(GL_COLOR_ATTACHMENT0);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, _vertexPixelBuffer);
    glReadPixels(0, 0, _width, _height, GL_RGB, GL_FLOAT, nil);
    // нормали
    glReadBuffer(GL_COLOR_ATTACHMENT1);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, _normalsPixelBuffer);
    glReadPixels(0, 0, _width, _height, GL_RGB, GL_FLOAT, nil);
    // текстурные координаты
    glReadBuffer(GL_COLOR_ATTACHMENT2);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, _texcoordPixelBuffer);
    glReadPixels(0, 0, _width, _height, GL_RGB, GL_FLOAT, nil);

    // выключаем фреймбуффер
    glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    //Восстанавливаем рисование в фоновый буфер
    glReadBuffer(GL_BACK);
    glDrawBuffer(GL_BACK);
    glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
    //Деактивируем текстуру
    glBindTexture(GL_TEXTURE_2D, 0);
}

-(void)prepareRenderingVAO{
    // создание 1го объекта
    glGenVertexArrays(1, &_modelVAO);
    glBindVertexArray(_modelVAO);
    
    // подгрузка буффера вершин
    glBindBuffer(GL_ARRAY_BUFFER, _vertexPixelBuffer);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
        
    // подгрузка нормалей
    glBindBuffer(GL_ARRAY_BUFFER, _normalsPixelBuffer);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, 0);
    
    // подгрузка текстурных координат
    glBindBuffer(GL_ARRAY_BUFFER, _texcoordPixelBuffer);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 0, 0);
    
    // генерим индексы отрисовки
    int step = 3;
    int w = _width / step;
    int h = _height / step;
    _modelElementsCount = w * h * 6;
    uint indexes[_modelElementsCount];
    uint k = 0;
    for(int i = 0; i < h; i++){
        for (int j = 0; j < w; j++) {
            indexes[k  ] = i*step + _width*j*step;
            indexes[k+1] = i*step + _width*j*step + _width * step;
            indexes[k+2] = i*step + _width*j*step + step;
            
            indexes[k+3] = i*step + _width*j*step + step;
            indexes[k+4] = i*step + _width*j*step + _width * step;
            indexes[k+5] = i*step + _width*j*step + _width * step + step;
            
            k += 6;
        }
    }
    
    // создание буффера индексов
    GLuint elementBufferName;
    glGenBuffers(1, &elementBufferName);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferName);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexes), indexes, GL_STATIC_DRAW);
    
    GetGLError();
}

-(void)generateShader{
    // модель
    _mvpMatrixLocation = glGetUniformLocation(ShadI.heightRenderShaderProgram, "u_mvpMatrix");
    _mvMatrixLocation = glGetUniformLocation(ShadI.heightRenderShaderProgram, "u_mvMatrix");
    _projMatrixLocation = glGetUniformLocation(ShadI.heightRenderShaderProgram, "u_projectionMatrix");
    _viewMatrixLocation =  glGetUniformLocation(ShadI.heightRenderShaderProgram, "u_viewMatrix");
    _modelMatrixLocation =  glGetUniformLocation(ShadI.heightRenderShaderProgram, "u_modelMatrix");
    _modelTextureLocation = glGetUniformLocation(ShadI.heightRenderShaderProgram, "u_texture");
    _lightPosWorlLocation = glGetUniformLocation(ShadI.heightRenderShaderProgram, "u_lightPosWorld");
}

-(void)renderModelFromCamera:(Camera*)cameraObj light:(LightObject*)light toShadow:(BOOL)toShadowMap customProj:(const mat4*)customProj{
    if (toShadowMap) {
        return;
    }
    
    // обновляем матрицу модели (ОБРАТНЫЙ ПОРЯДОК)
    mat4 modelMat = [self modelTransformMatrix];
    
    // камера вида
    mat4 camera = [cameraObj cameraMatrix];
    
    // проекция
    mat4 projection;
    if (customProj) {
        projection = *customProj;
    }else{
        projection = [self projectionMatrix];
    }
    
    mat4 mv = camera * modelMat;
    mat4 mvp = projection * mv;
    
    vec3 lightPosWorld = light.lightPos;
    
    // включаем шейдер для отрисовки
    [StatesI useProgramm:ShadI.heightRenderShaderProgram];
    
    // помещаем матрицу модельвидпроекция в шейдер (указываем)
    [StatesI setUniformMat4:_mvpMatrixLocation val:mvp];
    [StatesI setUniformMat4:_mvMatrixLocation val:mv];
    [StatesI setUniformMat4:_modelMatrixLocation val:modelMat];
    [StatesI setUniformMat4:_viewMatrixLocation val:camera];
    [StatesI setUniformMat4:_projMatrixLocation val:projection];
    [StatesI setUniformVec3:_lightPosWorlLocation val:lightPosWorld];
    
    // текстура модели
    [StatesI setUniformInt:_modelTextureLocation val:0];
    [StatesI activateTexture:GL_TEXTURE0 type:GL_TEXTURE_2D texId:_modelTexture];
    
    // включаем объект аттрибутов вершин
    [StatesI bindVAO:_modelVAO];
    if (_modelElementsCount > 0) {
        glDrawElements(GL_TRIANGLES, _modelElementsCount, GL_UNSIGNED_INT, 0);
    }
}

-(void)dealloc{
    // TODO: удаление текстур
    [super dealloc];
}

@end