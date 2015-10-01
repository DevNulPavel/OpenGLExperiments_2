#import "OpenGLRenderer.h"
#import <glm.hpp>
#import <ext.hpp>
#import "imageUtil.h"
#import "modelUtil.h"
#import "sourceUtil.h"
#import "VAOCreate.h"
#import "ShaderCreate.h"
#import "TextureCreate.h"
#import "FrameBufferCreate.h"
#import "GlobalValues.h"
#import "RenderObject.h"
#import "SkyModel3D.h"
#import "btBulletCollisionCommon.h"
#import "btBulletDynamicsCommon.h"
#import "AnimatedModel3D.h"
#import "GLStatesCache.h"
#import "ShadersCache.h"
#import "HeightMap.h"


using namespace glm;

@implementation OpenGLRenderer

GLint _spriteTextureLocation;
GLint _spriteVAO;
GLint _spriteElementsCount;


-(void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height {
	glViewport(0, 0, width, height);
    
	GlobI.viewWidth = width;
	GlobI.viewHeight = height;
    
    if (GlobI.shadowRenderFBO) {
        destroyFBO(GlobI.shadowRenderFBO);
        GlobI.shadowRenderFBO = 0;
        GlobI.shadowMapTexture = 0;
    }
    GLuint textId;
    GlobI.shadowRenderFBO = buildShadowFBO(GlobI.viewWidth * GlobI.shadowMapScale, GlobI.viewHeight * GlobI.shadowMapScale, &(textId));
    GlobI.shadowMapTexture = textId;
}

-(void)renderSprite{
    [StatesI useProgramm:ShadI.spriteShaderProgram];
    [StatesI setUniformInt:_spriteTextureLocation val:0];
    [StatesI activateTexture:GL_TEXTURE0 type:GL_TEXTURE_2D texId:GlobI.shadowMapTexture];
    
    [StatesI bindVAO:_spriteVAO];
    glDrawElements(GL_TRIANGLES, _spriteElementsCount, GL_UNSIGNED_INT, 0);
}

-(void)renderCube{
    vec3 offset = normalize(self.camera.cameraPos - GlobI.lookTargetPos) * vec3(2.0); // вычисляем вектор от найденной точки к позиции камеры
    vec3 position = GlobI.lookTargetPos + offset;
    self.pointingCube.modelPos = position;
    self.pointingCube.scale = 0.4 + length(position)/200.0;
    [self.pointingCube renderModelFromCamera:self.camera light:self.light toShadow:FALSE customProj:nil];
}

-(void)calcLookTarget{
    if (self.needCalcLookTarget == FALSE) {
        return;
    }
    
    GLint viewport[4];
    glGetIntegerv( GL_VIEWPORT, viewport );
    
    GLfloat winX = GlobI.viewWidth/2;
    GLfloat winY = GlobI.viewHeight/2;
    GLfloat winZ = 0;
    glReadPixels(int(winX), int(winY), 1, 1, GL_DEPTH_COMPONENT, GL_FLOAT, &winZ);
    
    if (winZ < 0.94) {
        GlobI.lookTargetPos = vec3(1000.0);
        return;
    }
    
    // обновляем матрицу модели (ОБРАТНЫЙ ПОРЯДОК)
    mat4 model;
    mat4 camera = [self.camera cameraMatrix];
    mat4 modelView = camera * model;
    
    // проекция
    mat4 projection = GlobI.projectionMatrix;
    
    // вьюпорт
    vec4 viewportVec = vec4(viewport[0], viewport[1], viewport[2], viewport[3]);
    
    GlobI.lookTargetPos = unProject(vec3(winX, winY, winZ), modelView, projection, viewportVec);
    self.needCalcLookTarget = FALSE;
}

-(void)renderToShadowMap{
    // увеличиваем угол поворота персонажа
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, GlobI.shadowRenderFBO);
    glClear(GL_DEPTH_BUFFER_BIT);
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
    glViewport(0, 0, GlobI.viewWidth * GlobI.shadowMapScale, GlobI.viewHeight * GlobI.shadowMapScale);
    for (RenderObject* model in self.models) {
        [model renderModelFromCamera:self.camera light:self.light toShadow:TRUE customProj:nil];
    }
    @synchronized(self.bullets) {
        for (RenderObject* bullet in self.bullets) {
            [bullet renderModelFromCamera:self.camera light:self.light toShadow:TRUE customProj:nil];
        }
    }
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glViewport(0, 0, GlobI.viewWidth, GlobI.viewHeight);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
}

-(void)renderToCubemapForPos:(vec3)pos{
    // увеличиваем угол поворота персонажа
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, GlobI.reflectionFBO);
    glViewport(0, 0, 512, 512);
    CameraContainer* camera = [[CameraContainer alloc] init];
    [camera setCameraPos:pos];
    [camera setCameraUp:vec3(0.0, 1.0, 0.0)];
    [camera setCameraTarget:vec3(0.0, 0.0, -1.0)];

    for (int i = 0; i < 6; ++i) {
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, GlobI.reflectionTexture, 0);
        glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
        
        mat4 curProjection = [GlobI cubemapProj:i];
        
        for (RenderObject* model in self.models) {
            [model renderModelFromCamera:camera light:self.light toShadow:FALSE customProj:&curProjection];
        }
        @synchronized(self.bullets) {
            for (RenderObject* bullet in self.bullets) {
                [bullet renderModelFromCamera:camera light:self.light toShadow:FALSE customProj:&curProjection];
            }
        }
        [self.skybox renderModelFromCamera:camera light:self.light toShadow:FALSE customProj:&curProjection];
    }
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    glViewport(0, 0, GlobI.viewWidth, GlobI.viewHeight);
    [camera release];
}

-(void)updatePhysics{
    if (self.isPhysicsCalc == TRUE) {
        return;
    }
    self.isPhysicsCalc = TRUE;
    float delta = GlobI.deltaTime;
    [GlobI rendered];
    PhysI.world->stepSimulation(delta);
    self.isPhysicsCalc = FALSE;
}

-(void)calcFPS{
    double now = [NSDate timeIntervalSinceReferenceDate];
    if((self.lastFPSUpdateTime + FPS_UPDATE_PERION) < now){
        float frameDelta = now - self.lastRenderTime;
        float curFps = 1.0 / frameDelta;
        [self.fpsLabel setText:[NSString stringWithFormat:@"%.1ffps", curFps]];
        self.lastFPSUpdateTime = now;
    }
    self.lastRenderTime = now;
}

-(void)render {
    [self.camera update];
    
    [self renderToShadowMap];
    
    // рендерим в кубимапу для отражений только если у нас видима модель
    if([self.skymodel isVisibleFromCamera:self.camera]){
        [self renderToCubemapForPos:self.skymodel.modelPos];
    }
    
    // очистим буфферы для отображения
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    for (RenderObject* model in self.models) {
        [model renderModelFromCamera:self.camera light:self.light toShadow:FALSE customProj:nil];
    }
    for (RenderObject* billboard in self.billboards) {
        [billboard renderModelFromCamera:self.camera light:self.light toShadow:FALSE customProj:nil];
    }
    @synchronized(self.bullets) {
        for (RenderObject* bullet in self.bullets) {
            [bullet renderModelFromCamera:self.camera light:self.light toShadow:FALSE customProj:nil];
        }
    }
    [self.skymodel renderModelFromCamera:self.camera light:self.light toShadow:FALSE customProj:nil];
    [self.skybox renderModelFromCamera:self.camera light:self.light toShadow:FALSE customProj:nil];
    
    [self calcLookTarget];
    [self renderCube];
    
    // спрайт для дебуга
    [self renderSprite];
    
    [self calcFPS];
    [self.fpsLabel renderModelFromCamera:self.camera light:self.light toShadow:FALSE customProj:nil];
}

-(void)shootCube{
    if (self.lastHitTime + 0.05 > [NSDate timeIntervalSinceReferenceDate]) {
        return;
    }
    self.lastHitTime = [NSDate timeIntervalSinceReferenceDate];
    
    Model3D* head = [[[Model3D alloc] initWithObjFilename:@"sphere" withBody:TRUE] autorelease];
    head.modelPos = self.camera.cameraPos + self.camera.cameraTargetVec * vec3(4.0);
    head.scale = 1.0;
    [head setMass:30];
    
    // через матрицы
//    mat4 rotateMat;
//    rotateMat = rotate(rotateMat, self.camera.horisontalAngle, vec3(0.0, 1.0, 0.0));
//    rotateMat = rotate(rotateMat, self.camera.verticalAngle, vec3(0.0, 0.0, 1.0));
//    head.rotateQuat = toQuat(rotateMat);
    
    // ищем поворот между направлением вперед и нужным направлением (чтобы стреляло вперед)
    quat rot1 = rotation(vec3(0.0f, 0.0f, 1.0f), self.camera.cameraTargetVec);
    // просчитываем направление направо
    vec3 desiredUp(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(self.camera.cameraTargetVec, desiredUp));
    // пересчитываем вектор вверх
    desiredUp = normalize(cross(right, self.camera.cameraTargetVec));
    vec3 newUp = normalize(rot1 * vec3(0.0f, 1.0f, 0.0f));
    // находим поворот вычисленного поворота пули для того, чтобы пуля сама по себе не вертелась вокруг оси z
    quat rot2 = rotation(newUp, desiredUp);
    // финальный поворот в обратном порядке
    head.rotateQuat = rot2 * rot1;
    
    // в цель
    vec3 toVec = self.camera.cameraTargetVec * vec3(300.0);
    [head setVelocity:toVec];
    
    [head addToPhysicsWorld];
    
    @synchronized(self.bullets) {
        [self.bullets addObject:head];
    }
}

-(void)keyButtonUp:(NSString*)chars{
    [self.camera keyButtonUp:chars];
}

-(void)keyButtonDown:(NSString*)chars{
    [self.camera keyButtonDown:chars];
    
    for (int i = 0; i < chars.length; i++) {
        unichar character = [chars characterAtIndex:i];
        switch (character) {
            case 'r':{
                [self shootCube];
            }break;
        }
    }
}

-(void)mouseMoved:(float)deltaX deltaY:(float)deltaY{
    self.needCalcLookTarget = TRUE;
    [self.camera mouseMoved:deltaX deltaY:deltaY];
}

-(void)testCode{
    {
        vec3 front(0.0, 0.0, 0.1);
        vec3 right(1.0, 0.0, 0.0);
        vec3 mulValue = normalize(front * right);  // произведение векторов
        mulValue = mulValue;
    }
    {
        vec3 front(0.0, 0.0, 1.0);
        vec3 right(1.0, 0.0, 0.0);
        vec3 sumValue = normalize(front + right);  // сумма векторов
        sumValue = sumValue;
    }
    {
        vec3 front(0.0, 0.0, 1.0);
        vec3 right(0.0, 0.0, 0.5);
        vec3 subValue = normalize(front - right);  // разница векторов (как из второй точки, попасть в первую)
        subValue = subValue;
    }
    {
        vec3 front(0.0, 0.0, 1.0);
        vec3 right(0.5, 0.0, 0.5);
        float cosCoeff = dot(normalize(front), normalize(right)); // насколько сильно эти вектора сонаправлены друг с другом (косинус угла между ними)
        cosCoeff = cosCoeff;
    }
    {
        vec3 front(0.0, 0.0, 1.0);
        vec3 right(1.0, 0.0, 0.0);
        vec3 vectMul = cross(front, right); // векторное произведение по правилу левой руки (указательный вперед 1, средний направо 2 = большой смотрит вверх)
        vectMul = vectMul;
    }
    {
        vec3 front(0.0, 0.0, 1.0);
        vec3 right(1.0, 0.0, 0.0);
        float res = angle(front, right); // угол между векторами
        res = orientedAngle(front, right, vec3(1.0, 0.0, 0.0))/M_PI*180.0; // угол между векторами
        res = res;
    }
    {
        vec3 front(0.0, 0.0, 1.0);
        vec3 right(1.0, 0.0, 0.0);
        float res = angle(front, right); // угол между векторами
        res = orientedAngle(front, right, vec3(1.0, 0.0, 0.0))/M_PI*180.0; // угол между векторами
        res = res;
    }
}

- (id) initWithWidth:(int)width height:(int)height {
	if((self = [super init])) {
		NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));
        GLint texture_units;
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &texture_units);
        
        [self testCode];
        
        self.camera = [[[Camera alloc] initWithCameraPos:GlobI.cameraInitPos] autorelease];
        self.light = [[[LightObject alloc] init] autorelease];
        PhysI;
        
		GlobI.viewWidth = width;
		GlobI.viewHeight = height;
        
        ////////////////////////////////////////////////
        // буфер рендеринга
        ////////////////////////////////////////////////
        
        GLuint texture;
        // фреймбуффер для тени
        GlobI.shadowRenderFBO = buildShadowFBO(GlobI.viewWidth * GlobI.shadowMapScale, GlobI.viewHeight * GlobI.shadowMapScale, &texture);
        GlobI.shadowMapTexture = texture;
        // фреймбуффер для отражений
        GlobI.reflectionFBO = buildCubeFBO(&texture, 512, 512);
        GlobI.reflectionTexture = texture;
        
		//////////////////////////////
		// модель //
		//////////////////////////////
		
        self.models = [NSMutableArray array];
        self.billboards = [NSMutableArray array];
        self.bullets = [NSMutableArray array];
        
        {
            // скабокс
            self.skybox = [[[Skybox alloc] init] autorelease];
            
            // модель
            Model3D* modelOld = [[[Model3D alloc] initWithFilename:@"demon"] autorelease];
            modelOld.modelPos = vec3(-40.0, 0.0, -40.0);
            modelOld.scale = 0.1;
            modelOld.rotateQuat = angleAxis(float(-M_PI_2), vec3(1.0, 0.0, 0.0));
            [self.models addObject:modelOld];
            
            // модель голов
            for(int i = 0; i < 25; i++){
                Model3D* head = [[[Model3D alloc] initWithObjFilename:@"african_head" withBody:TRUE] autorelease];
                head.modelPos = vec3(randomFloat(-40.0, 40.0), randomFloat(-40.0, 40.0), randomFloat(-40.0, 40.0));
                head.scale = 8.0;
                
                // в центр
                vec3 toCenterVec = normalize(-head.modelPos) * vec3(10.0);
                [head setVelocity:toCenterVec];
                [head setMass:100.0];
                [head addToPhysicsWorld];
                [self.models addObject:head];
            }
            
            // скай модель
            SkyModel3D* skyModel = [[[SkyModel3D alloc] initWithFilename:@"demon"] autorelease];
            skyModel.modelPos = vec3(30.0, 0.0, -30.0);
            skyModel.scale = 0.1;
            skyModel.rotateQuat = angleAxis(float(-M_PI_2), vec3(1.0, 0.0, 0.0));
            skyModel.boxTexture = GlobI.reflectionTexture;
            self.skymodel = skyModel;
            
            // частицы
            ParticlesModel* particles = [[[ParticlesModel alloc] init] autorelease];
            particles.modelPos = vec3(40.0, 10.0, 0.0);
            particles.scale = 9;
            [self.models addObject:particles];
        }
        {
            // биллборд, например, дерево
            for(int i = 0; i < 20; i++){
                BillboardModel* billboard = [[[BillboardModel alloc] initOne] autorelease];
                billboard.scale = 5.0;
                billboard.modelPos = vec3(randomFloat(-60.0, 60), -GlobI.worldSize.y/2.0 + billboard.scale, randomFloat(-60.0, 60));
                [self.billboards addObject:billboard];
            }
            // биллборд в духе частиц
            std::vector<vec3> positions;
            for(int i = 0; i < 15; i++){
                vec3 pos(randomFloat(-5, 5), randomFloat(-5, 5), randomFloat(-5, 5));
                positions.push_back(pos);
            }
            BillboardModel* billboard = [[[BillboardModel alloc] initWithPositions:positions] autorelease];
            billboard.modelPos = vec3(-40, -40, -20);
            billboard.scale = 20.0;
            [self.billboards addObject:billboard];
        }
        
        AnimatedModel3D* animatedModel = [[[AnimatedModel3D alloc] initWithFilename:@"boblampclean.md5mesh" animIndex:0 withBody:TRUE] autorelease];
        animatedModel.scale = 0.5;
        animatedModel.modelPos = vec3(0.0, -20.0, 10.0);
        animatedModel.rotateQuat = angleAxis(float(-M_PI_2), vec3(1.0, 0.0, 0.0));
        [animatedModel setMass:400.0];
        [animatedModel addToPhysicsWorld];
        [self.models addObject:animatedModel];
        
        // карта высот по текстуре
        HeightMap* heightMap = [[[HeightMap alloc] init] autorelease];
        heightMap.scale = 10;
        heightMap.modelPos = vec3(0.0, 0.0, 0.0);
        [self.models addObject:heightMap];
        
        // текст
        self.fpsLabel = [[[LabelModel alloc] initWithText:@"----" fontSize:25] autorelease];
        self.fpsLabel.modelPos = vec3(0, 0, 0);
        
        // тестовый выстрел
        [self shootCube];
        
        // куб указатель
        self.pointingCube = [[[CubeModel alloc] init] autorelease];
        self.pointingCube.scale = 0.5;
        
		// на основании модели создаем обхект аттрибутов вершин
        _spriteVAO = debugSpriteVAO(&_spriteElementsCount);
        glBindVertexArray(0);
        
		////////////////////////////////////////////////////
		// создание шейдера
		////////////////////////////////////////////////////
        
        // спрайт
        _spriteTextureLocation = glGetUniformLocation(ShadI.spriteShaderProgram, "u_texture");
        
		////////////////////////////////////////////////
		// настройка GL
		////////////////////////////////////////////////
		
        [StatesI enableState:GL_CULL_FACE];     // не рисует заднюю часть
		[StatesI enableState:GL_DEPTH_TEST];    // тест глубины
		
		// цвет фона
		glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
        
		// Check for errors to make sure all of our setup went ok
		GetGLError();
	}
	
	return self;
}

- (void) dealloc {
    self.camera = nil;
    self.models = nil;
    self.billboards = nil;
    self.light = nil;
    self.pointingCube = nil;
    self.bullets = nil;
    self.skybox = nil;
    self.fpsLabel = nil;
    
    destroyVAO(_spriteVAO);
    
	[super dealloc];
}

@end
