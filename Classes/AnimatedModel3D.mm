//
//  Model3D.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "AnimatedModel3D.h"
#import "GlobalValues.h"
#import "ObjModelVAO.h"
#import "VAOCreate.h"
#import "TextureCreate.h"
#import "ShadersCache.h"
#import "ShaderCreate.h"
#import "GlobalValues.h"
#import "ObjModelPhysShape.h"
#import "PhysicsLogic.h"
#import "GLStatesCache.h"

// ВАЖНО !!!!!
// в ASSIMP матрицы транспонированные !!!
// меняется индекс
mat4 aiToGlmMatrix(const aiMatrix4x4& aiMat4x4){
    mat4 result;
    for (int i = 0; i < 4; i++) {
        for(int j = 0; j < 4; j++){
            result[i][j] = aiMat4x4[j][i];
        }
    }
    return result;
}

vec3 aiToGlmVec3(const aiVector3D& aiVec){
    vec3 result(aiVec.x, aiVec.y, aiVec.z);
    return result;
}

quat aiToGlmQuat(const aiQuaternion& aiQuat){
    quat result;
    result.x = aiQuat.x;
    result.y = aiQuat.y;
    result.z = aiQuat.z;
    result.w = aiQuat.w;
    return result;
}

btVector3 glmVec3ToBt(const vec3& vec){
    btVector3 result(vec.x, vec.y, vec.z);
    return result;
}


@implementation AnimatedModel3D

-(id)initWithFilename:(NSString *)filename animIndex:(int)animIndex withBody:(BOOL)withBody{
    if ((self = [super init])) {
        self.curAnimationIndex = animIndex;
        [self loadScene:filename];
        [self updateBoneTransforms];
        
        [self generateShader];
        if (withBody) {
            [self createPhysicsBody];
        }
    }
    return self;
}


-(void)loadScene:(NSString*)filename{
    NSString* filePathName = [[NSBundle mainBundle] pathForResource:filename ofType:nil];
    const char* cPath = [filePathName cStringUsingEncoding:NSASCIIStringEncoding];
    _scene = _importer.ReadFile(cPath, aiProcess_ValidateDataStructure | aiProcess_GenSmoothNormals | aiProcess_Triangulate | aiProcess_CalcTangentSpace | aiProcess_FlipUVs | aiProcess_OptimizeMeshes | aiProcess_JoinIdenticalVertices | aiProcess_FixInfacingNormals);
    
    assert(_scene != nil);
    
    // обратный трансформ сцены
    aiMatrix4x4 aiGlobTrans = _scene->mRootNode->mTransformation;
    aiGlobTrans.Inverse();
    _globalInverseTransform = aiToGlmMatrix(aiGlobTrans);
    
    // ресайз инфы для рендера
    _entries.resize(_scene->mNumMeshes);
    _textures.resize(_scene->mNumMaterials);
    
    // инфа вершин
    uint numVertices = 0;
    uint numIndexes = 0;
    
    // формируем список для отрисовки
    for (int i = 0; i < _entries.size(); i++) {
        // заполнение инфой
        _entries[i].materialIndex = _scene->mMeshes[i]->mMaterialIndex;
        _entries[i].numIndexes = _scene->mMeshes[i]->mNumFaces * 3;
        _entries[i].baseVertex = numVertices;
        _entries[i].baseIndex = numIndexes;
        // смещения
        numVertices += _scene->mMeshes[i]->mNumVertices;
        numIndexes += _entries[i].numIndexes;
    }
    
    // резервироание памяти
    _positions.reserve(numVertices);
    _normals.reserve(numVertices);
    _texCoords.reserve(numVertices);
    _tangents.reserve(numVertices);
    _bitangents.reserve(numVertices);
    _indexes.reserve(numVertices);
    // и выделяем под кости
    _bones.resize(numVertices);
    
    // загрузка мешей сцены в память
    for(uint i = 0; i < _entries.size(); i++){
        const aiMesh* mesh = _scene->mMeshes[i];
        [self loadDataMeshIndex:i fromMesh:mesh
                            pos:_positions norm:_normals
                             uv:_texCoords tan:_tangents bitan:_bitangents
                          bones:_bones tan:_indexes];
    }
    
    // баунд бокс
    BoudndingBox box;
    box.leftBotomNear = vec3(_minimum.x, _minimum.y, _minimum.z);
    box.rightBotomNear = vec3(_maximum.x, _minimum.y, _minimum.z);
    box.leftTopNear = vec3(_minimum.x, _maximum.y, _minimum.z);
    box.rightTopNear = vec3(_maximum.x, _maximum.y, _minimum.z);
    
    box.leftBotomFar = vec3(_minimum.x, _minimum.y, _maximum.z);
    box.rightBotomFar = vec3(_maximum.x, _minimum.y, _maximum.z);
    box.leftTopFar = vec3(_minimum.x, _maximum.y, _maximum.z);
    box.rightTopFar = vec3(_maximum.x, _maximum.y, _maximum.z);
    
    self.boundBox = box;
    
    // грузим текстуры
    _textures.resize(_scene->mNumMaterials);
    _normalTextures.resize(_scene->mNumMaterials);
    [self loadTextures:_scene filename:filename];
    
    // создание 1го объекта
    glGenVertexArrays(1, &_vao);
    [StatesI bindVAO:_vao];
    
    // сразу создаем буфферы
    glGenBuffers(ATTRIBUTE_BUFFERS_COUNT, _buffers);
    
    // создаем буффер вершин
    glBindBuffer(GL_ARRAY_BUFFER, _buffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_positions[0]) * _positions.size(), &_positions[0], GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIBUTE_POSITION);
    glVertexAttribPointer(ATTRIBUTE_POSITION, 4, GL_FLOAT, GL_FALSE, 0, 0);
    
    // создаем буффер объект для нормалей
    glBindBuffer(GL_ARRAY_BUFFER, _buffers[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_normals[0]) * _normals.size(), &_normals[0], GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIBUTE_NORMAL);
    glVertexAttribPointer(ATTRIBUTE_NORMAL, 3, GL_FLOAT, GL_FALSE, 0, 0);
    
    // создаем буффер объект для координат текстур
    glBindBuffer(GL_ARRAY_BUFFER, _buffers[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_texCoords[0]) * _texCoords.size(), &_texCoords[0], GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIBUTE_UV);
    glVertexAttribPointer(ATTRIBUTE_UV, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    // создаем буффер объект тангенса
    glBindBuffer(GL_ARRAY_BUFFER, _buffers[3]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_tangents[0]) * _tangents.size(), &_tangents[0], GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIBUTE_TANGENT);
    glVertexAttribPointer(ATTRIBUTE_TANGENT, 3, GL_FLOAT, GL_FALSE, 0, 0);
    
    // создаем буффер объект бинормалей
    glBindBuffer(GL_ARRAY_BUFFER, _buffers[4]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_bitangents[0]) * _bitangents.size(), &_bitangents[0], GL_STATIC_DRAW);
    glEnableVertexAttribArray(ATTRIBUTE_BITANGENT);
    glVertexAttribPointer(ATTRIBUTE_BITANGENT, 3, GL_FLOAT, GL_FALSE, 0, 0);
    
    // данные по костям
    glBindBuffer(GL_ARRAY_BUFFER, _buffers[5]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_bones[0]) * _bones.size(), &_bones[0], GL_STATIC_DRAW);
    // указываем как эти кости читать
    // иды костей  (ВАЖНО !!! - glVertexAttribIPointer)
    glEnableVertexAttribArray(ATTRIBUTE_BONE_IDS);
    glVertexAttribIPointer(ATTRIBUTE_BONE_IDS, 4, GL_UNSIGNED_INT, sizeof(_bones[0]), 0);
    // веса костей
    glEnableVertexAttribArray(ATTRIBUTE_BONE_WEIGHTS);
    glVertexAttribPointer(ATTRIBUTE_BONE_WEIGHTS, 4, GL_FLOAT, GL_FALSE, sizeof(_bones[0]), (const GLvoid*)sizeof(_bones[0].ids));
    
    // индексы
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _buffers[6]); // это массив индексов
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(_indexes[0]) * _indexes.size(), &_indexes[0], GL_STATIC_DRAW);
    
}

-(void)loadDataMeshIndex:(uint)meshIndex fromMesh:(const aiMesh*)mesh
                     pos:(vector<vec4>&)positions norm:(vector<vec3>&)normals
                      uv:(vector<vec2>&)uvCoords tan:(vector<vec3>&)tangents bitan:(vector<vec3>&)bitan
                   bones:(vector<VertexBoneData>&)bones tan:(vector<uint>&)indexes{
    
    // данный о фигуре
    aiVector3D nullVec(0.0, 0.0, 0.0);
    for (uint i = 0; i < mesh->mNumVertices; i++) {
        // вершина
        aiVector3D aiPos = mesh->HasPositions() ? mesh->mVertices[i] : nullVec;
        vec4 vertex(aiPos.x, aiPos.y, aiPos.z, 1.0);
        positions.push_back(vertex);
        // нормаль
        aiVector3D aiNormal = mesh->HasNormals() ? mesh->mNormals[i] : nullVec;
        vec3 normal(aiNormal.x, aiNormal.y, aiNormal.z);
        normals.push_back(normal);
        // текстурные координаты
        aiVector3D aiUVCoord = mesh->HasTextureCoords(0) ? mesh->mTextureCoords[0][i] : nullVec;
        vec2 uv(aiUVCoord.x, aiUVCoord.y);
        uvCoords.push_back(uv);
        // тангенс
        aiVector3D aiTangens = mesh->HasTangentsAndBitangents() ? mesh->mTangents[i] : nullVec;
        vec3 tangen(aiTangens.x, aiTangens.y, aiTangens.z);
        tangents.push_back(tangen);
        // битанг
        aiVector3D aiBitan = mesh->HasTangentsAndBitangents() ? mesh->mBitangents[i] : nullVec;
        vec3 bitangent(aiBitan.x, aiBitan.y, aiBitan.z);
        bitan.push_back(bitangent);
        
        // вычислим размер для физического тела
        float maxX = MAX(vertex.x, _maximum.x);
        float maxY = MAX(vertex.y, _maximum.y);
        float maxZ = MAX(vertex.z, _maximum.z);
        _maximum = vec3(maxX, maxY, maxZ);
        float minX = MIN(vertex.x, _minimum.x);
        float minY = MIN(vertex.y, _minimum.y);
        float minZ = MIN(vertex.z, _minimum.z);
        _minimum = vec3(minX, minY, minZ);
    }
    
    // подгружаем кости меша
    [self loadBones:meshIndex fromMesh:mesh toBones:bones];
    
    // формируем массив индексов
    for (int i = 0; i < mesh->mNumFaces; i++) {
        aiFace face = mesh->mFaces[i];
        assert(face.mNumIndices == 3);
        GLuint index1 = face.mIndices[0];
        GLuint index2 = face.mIndices[1];
        GLuint index3 = face.mIndices[2];
        indexes.push_back(index1);
        indexes.push_back(index2);
        indexes.push_back(index3);
    }
}

-(void)loadBones:(uint)meshIndex fromMesh:(const aiMesh*)mesh toBones:(vector<VertexBoneData>&)bones{
    for(uint i = 0; i < mesh->mNumBones; i++){
        uint boneIndex = 0;
        string boneName(mesh->mBones[i]->mName.data);
        
        // распределение
        if (_boneMapping.find(boneName) == _boneMapping.end()) {
            // создадим индекс для новой кости
            boneIndex = _numBones;
            _numBones++;
            // инфа кости
            BoneInfo boneInfo;
            _boneInfos.push_back(boneInfo);
            _boneInfos[boneIndex].boneOffset = aiToGlmMatrix(mesh->mBones[i]->mOffsetMatrix);
            // маппинг
            _boneMapping[boneName] = boneIndex;
        }else{
            boneIndex = _boneMapping[boneName];
        }
        
        // подгрузка инфы по костям (ид вершины и вес)
        const aiBone* curBone = mesh->mBones[i];
        for (uint j = 0; j < curBone->mNumWeights; j++) {
            uint vertexId = _entries[meshIndex].baseVertex + curBone->mWeights[j].mVertexId;
            float weight = curBone->mWeights[j].mWeight;
            bones[vertexId].addBoneData(boneIndex, weight);
        }
    }
}

-(void)loadTextures:(const aiScene*)scene filename:(NSString*)filename{
    for(uint i = 0; i < scene->mNumMaterials; i++){
        const aiMaterial* material = scene->mMaterials[i];
        
        // обнуляем текстуры
        _textures[i] = 0;
        _normalTextures[i] = 0;
        
        // диффузная текстура
        if (material->GetTextureCount(aiTextureType_DIFFUSE) > 0) {
            aiString path;
            if (material->GetTexture(aiTextureType_DIFFUSE, 0, &path) == AI_SUCCESS) {
                NSString* filePathOrigin = [NSString stringWithCString:path.data encoding:NSASCIIStringEncoding];

                NSString* pngName = filePathOrigin;
                NSString* normalsName = [pngName stringByReplacingOccurrencesOfString:@".png" withString:@"_normals.png"];
                
                GLint textureId = buildTextureWithExt(pngName, nil);
                GLint normalsId = buildTextureWithExt(normalsName, nil);
                _textures[i] = textureId;
                _normalTextures[i] = normalsId;
            }
        }
    }
}

#pragma mark - Animation interpolation

-(uint)findPosition:(float)animationTime animNode:(const aiNodeAnim*)nodeAnim{
    assert(nodeAnim->mNumPositionKeys > 0);
    for (uint i = 0; i < nodeAnim->mNumPositionKeys - 1; i++) {
        if (animationTime < nodeAnim->mPositionKeys[i+1].mTime) {
            return i;
        }
    }
    assert(0);
    return 0;
}

-(uint)findRotation:(float)animationTime animNode:(const aiNodeAnim*)nodeAnim{
    assert(nodeAnim->mNumRotationKeys > 0);
    for (uint i = 0; i < nodeAnim->mNumRotationKeys - 1; i++) {
        if (animationTime < nodeAnim->mRotationKeys[i+1].mTime) {
            return i;
        }
    }
    assert(0);
    return 0;
}

-(uint)findScaling:(float)animationTime animNode:(const aiNodeAnim*)nodeAnim{
    assert(nodeAnim->mNumScalingKeys > 0);
    for (uint i = 0; i < nodeAnim->mNumScalingKeys - 1; i++) {
        if (animationTime < nodeAnim->mScalingKeys[i+1].mTime) {
            return i;
        }
    }
    assert(0);
    return 0;
}

-(vec3)calcInterpolatedPosition:(float)animationTime animNode:(const aiNodeAnim*)nodeAnim{
    if(nodeAnim->mNumPositionKeys == 1){
        vec3 res = aiToGlmVec3(nodeAnim->mPositionKeys[0].mValue);
        return res;
    }
    
    uint positionIndex = [self findPosition:animationTime animNode:nodeAnim];
    uint nextPositionIndex = (positionIndex + 1);
    assert(nextPositionIndex < nodeAnim->mNumPositionKeys);
    
    float deltaTime = (float)(nodeAnim->mPositionKeys[nextPositionIndex].mTime - nodeAnim->mPositionKeys[positionIndex].mTime);
    float factor = (animationTime - (float)nodeAnim->mPositionKeys[positionIndex].mTime) / deltaTime;
    assert((factor >= 0.0f) && (factor <= 1.0f));
    
    const aiVector3D& start = nodeAnim->mPositionKeys[positionIndex].mValue;
    const aiVector3D& end = nodeAnim->mPositionKeys[nextPositionIndex].mValue;
    aiVector3D delta = end - start;
    aiVector3D outResult = start + factor * delta;
    
    vec3 result = aiToGlmVec3(outResult);
    return result;
}

-(quat)calcInterpolatedRotation:(float)animationTime animNode:(const aiNodeAnim*)nodeAnim{
    if(nodeAnim->mNumRotationKeys == 1){
        quat res = aiToGlmQuat(nodeAnim->mRotationKeys[0].mValue);
        return res;
    }
    
    uint positionIndex = [self findRotation:animationTime animNode:nodeAnim];
    uint nextPositionIndex = (positionIndex + 1);
    assert(nextPositionIndex < nodeAnim->mNumRotationKeys);
    
    float deltaTime = (float)(nodeAnim->mRotationKeys[nextPositionIndex].mTime - nodeAnim->mRotationKeys[positionIndex].mTime);
    float factor = (animationTime - (float)nodeAnim->mRotationKeys[positionIndex].mTime) / deltaTime;
    assert((factor >= 0.0f) && (factor <= 1.0f));
    
    const aiQuaternion& start = nodeAnim->mRotationKeys[positionIndex].mValue;
    const aiQuaternion& end = nodeAnim->mRotationKeys[nextPositionIndex].mValue;
    aiQuaternion outResult;
    aiQuaternion::Interpolate(outResult, start, end, factor);
    outResult = outResult.Normalize();
    
    quat result = aiToGlmQuat(outResult);
    return result;
}

-(vec3)calcInterpolatedScaling:(float)animationTime animNode:(const aiNodeAnim*)nodeAnim{
    if(nodeAnim->mNumScalingKeys == 1){
        vec3 res = aiToGlmVec3(nodeAnim->mScalingKeys[0].mValue);
        return res;
    }
    
    uint positionIndex = [self findScaling:animationTime animNode:nodeAnim];
    uint nextPositionIndex = (positionIndex + 1);
    assert(nextPositionIndex < nodeAnim->mNumScalingKeys);
    
    float deltaTime = (float)(nodeAnim->mScalingKeys[nextPositionIndex].mTime - nodeAnim->mScalingKeys[positionIndex].mTime);
    float factor = (animationTime - (float)nodeAnim->mScalingKeys[positionIndex].mTime) / deltaTime;
    assert((factor >= 0.0f) && (factor <= 1.0f));
    
    const aiVector3D& start = nodeAnim->mScalingKeys[positionIndex].mValue;
    const aiVector3D& end = nodeAnim->mScalingKeys[nextPositionIndex].mValue;
    aiVector3D delta = end - start;
    aiVector3D outResult = start + factor * delta;
    
    vec3 result = aiToGlmVec3(outResult);
    return result;
}

-(void)readNodeHierarchy:(float) animationTime node:(const aiNode*)node parentTransform:(const mat4&)parentTransform{
    
    // тут менять ид анимации
    const aiAnimation* animation = _scene->mAnimations[self.curAnimationIndex];

    string nodeName(node->mName.data);
    const aiNodeAnim* nodeAnim = [self findNodeAnim:animation name:nodeName];

    mat4 nodeTransform = aiToGlmMatrix(node->mTransformation);
    if (nodeAnim) {
        vec3 scaleVec = [self calcInterpolatedScaling:animationTime animNode:nodeAnim];
        mat4 scaleMat = scale(mat4(1.0), scaleVec);
        
        quat rotateQuat = [self calcInterpolatedRotation:animationTime animNode:nodeAnim];
        mat4 rotateMat = toMat4(rotateQuat);
        
        vec3 translateVec = [self calcInterpolatedPosition:animationTime animNode:nodeAnim];
        mat4 translateMat = translate(mat4(1.0), translateVec);
        
        nodeTransform = translateMat * rotateMat * scaleMat;
    }
    
    // трансформ относительно всей модели
    mat4 globalTransform = parentTransform * nodeTransform;
    
    // обновляем трансформы для костей
    if (_boneMapping.find(nodeName) != _boneMapping.end()) {
        uint boneIndex = _boneMapping[nodeName];
        _boneInfos[boneIndex].finalTransform = _globalInverseTransform * globalTransform * _boneInfos[boneIndex].boneOffset;
    }
    
    // обходим чилдов и обновляем их трансформы
    for (uint i = 0 ; i < node->mNumChildren ; i++) {
        [self readNodeHierarchy:animationTime node:node->mChildren[i] parentTransform:globalTransform];
    }
}

-(void)boneTransform:(float)timeInSec transforms:(vector<mat4>&) transforms{
    // узнаем частоту
    const aiAnimation* anim = _scene->mAnimations[self.curAnimationIndex];
    float ticksPerSecond = (float)(anim->mTicksPerSecond != 0 ? anim->mTicksPerSecond : 25.0f);
    float timeInTicks = timeInSec * ticksPerSecond;
    float animationTime = fmod(timeInTicks, (float)anim->mDuration);

    mat4 identity(1.0);
    [self readNodeHierarchy:animationTime node:_scene->mRootNode parentTransform:identity];
    
    transforms.resize(_numBones);
    for (uint i = 0 ; i < _numBones ; i++) {
        transforms[i] = _boneInfos[i].finalTransform;
    }
}

-(const aiNodeAnim*)findNodeAnim:(const aiAnimation*)animation name:(string)nodeName{
    for (uint i = 0 ; i < animation->mNumChannels ; i++) {
        const aiNodeAnim* pNodeAnim = animation->mChannels[i];
        if (string(pNodeAnim->mNodeName.data) == nodeName) {
            return pNodeAnim;
        }
    }
    return NULL;
}

#pragma mark - Physics

-(btConvexHullShape*)makeCapsuleShape{
    btConvexHullShape* shape = new btConvexHullShape();
    {
        btVector3 leftBot = glmVec3ToBt(self.boundBox.leftBotomNear);
        btVector3 rightBot = glmVec3ToBt(self.boundBox.rightBotomNear);
        btVector3 leftTop = glmVec3ToBt(self.boundBox.leftTopNear);
        btVector3 rightTop = glmVec3ToBt(self.boundBox.rightTopNear);
        shape->addPoint(leftBot);
        shape->addPoint(rightBot);
        shape->addPoint(leftTop);
        shape->addPoint(rightTop);
    }
    {
        btVector3 leftBot = glmVec3ToBt(self.boundBox.leftBotomFar);
        btVector3 rightBot = glmVec3ToBt(self.boundBox.rightBotomFar);
        btVector3 leftTop = glmVec3ToBt(self.boundBox.leftTopFar);
        btVector3 rightTop = glmVec3ToBt(self.boundBox.rightTopFar);
        shape->addPoint(leftBot);
        shape->addPoint(rightBot);
        shape->addPoint(leftTop);
        shape->addPoint(rightTop);
    }
    return shape;
}

-(btConvexHullShape*)makeShape{
    btConvexHullShape* shape = new btConvexHullShape();
    for (int i = 0; i < _positions.size(); i++) {
        // дергаем трансформ костей
        uint* boneIds = _bones[i].ids;
        float* boneWeights = _bones[i].weights;
        mat4 transformMatrix(0.0);
        for(int i = 0; i < NUM_BONES_PER_VEREX; i++){
            int boneId = boneIds[i];
            float boneWeight = boneWeights[i];
            transformMatrix += _resultBonesTransforms[boneId] * boneWeight;
        }
        
        // домножаем на костевую анимацию
        vec4 vertex = _positions[i];
        vec4 pos = transformMatrix * vertex;
        
        btVector3 bv = btVector3(pos.x, pos.y, pos.z);
        shape->addPoint(bv);
    }
    return shape;
}

-(void)updatePhysicsBody{
    return;
    [self removeFromPhysicsWorld];
    
    // новая фигура
    btConvexHullShape* newShape = [self makeShape];
    self.body->setCollisionShape(newShape);
    
    // обновим указатель
    if (self.shape) {
        delete self.shape;
    }
    self.shape = newShape;
    
    // скейл
    self.shape->setLocalScaling(btVector3(self.scale, self.scale, self.scale));
    
    // масса
    btVector3 bodyInertia;
    self.shape->calculateLocalInertia(self.bodyMass, bodyInertia);
    self.body->setMassProps(self.bodyMass, bodyInertia);
    self.body->updateInertiaTensor();
    
    [self addToPhysicsWorld];
}

-(void)createPhysicsBody{
    self.shape = [self makeCapsuleShape];
//    self.shape->setLocalScaling(btVector3(self.scale, self.scale, self.scale));
    
    // углы поворота через zyx
    btQuaternion rotation(self.rotateQuat.x, self.rotateQuat.y, self.rotateQuat.x, self.rotateQuat.w);
    
    // позиция фигуры
    btVector3 position = btVector3(self.modelPos.x, self.modelPos.y, self.modelPos.z);
    
    // движение
    btDefaultMotionState* motionState = new btDefaultMotionState(btTransform(rotation, position));
    
    // масса и инерция
    btScalar bodyMass = 0.0;
    btVector3 bodyInertia;
    self.shape->calculateLocalInertia(bodyMass, bodyInertia);
    
    //5
    btRigidBody::btRigidBodyConstructionInfo bodyCI = btRigidBody::btRigidBodyConstructionInfo(bodyMass, motionState, self.shape, bodyInertia);
    
    //6
    bodyCI.m_restitution = 0.1f;    // сила отскока 0 - нету, 0-1 - с затуханием, >1 - с усилением
    bodyCI.m_friction = 0.8f;       // сопротивление скольжению
    
    //7
    self.body = new btRigidBody(bodyCI);
    
    //8
//    self.body->setUserPointer((__bridge void*)self);
    
    //9
    self.body->setAngularFactor(0.3);   // угол ?
    self.body->setLinearFactor(btVector3(1.2, 1.2, 1.2));   // небольшой отскок
    self.body->setDamping(0.4, 0.7);  // затухание полета и поворота (сопр-е воздуха)
}

-(void)addToPhysicsWorld{
    PhysI.world->addRigidBody(self.body);
}

-(void)removeFromPhysicsWorld{
    PhysI.world->removeRigidBody(self.body);
}

-(void)setModelPos:(vec3)modelPos {
    [super setModelPos:modelPos];
    [self updateBody];
}

-(void)setRotateQuat:(quat)rotateQuat{
    [super setRotateQuat:rotateQuat];
    [self updateBody];
}

-(void)setScale:(float)scale{
    [super setScale:scale];
    [self updateBody];
}

-(void)updateBody{
    if (self.body) {
        btTransform trans = self.body->getWorldTransform();
        // углы поворота через zyx
        btQuaternion rotation(self.rotateQuat.x, self.rotateQuat.y, self.rotateQuat.z, self.rotateQuat.w);
        trans.setRotation(rotation);
        // позиция
        btVector3 position = btVector3(self.modelPos.x, self.modelPos.y, self.modelPos.z);
        trans.setOrigin(position);
        // обновляем
        self.body->setWorldTransform(trans);
        
        // скейл
        self.shape->setLocalScaling(btVector3(self.scale, self.scale, self.scale));
    }
}

-(mat4)modelTransformMatrix{
    if (self.body) {
        btTransform trans = self.body->getWorldTransform();
        // позиция
        btVector3 pos = trans.getOrigin();
        // повороты
        btQuaternion rotationQuanterion = trans.getRotation();
        float angle = rotationQuanterion.getAngle();
        btVector3 axis = rotationQuanterion.getAxis();
        
        // скейл
        btVector3 scaleVec = self.shape->getLocalScaling();
        
        // обновляем матрицу модели (ОБРАТНЫЙ ПОРЯДОК)
        mat4 modelMat;
        modelMat = translate(modelMat, vec3(pos.x(), pos.y(), pos.z()));
        modelMat = rotate(modelMat, angle, vec3(axis.x(), axis.y(), axis.z()));
        modelMat = scale(modelMat, vec3(scaleVec.x(), scaleVec.y(), scaleVec.z()));
        return modelMat;
    }else{
        return [super modelTransformMatrix];
    }
}

-(void)setMass:(float)mass{
    if (self.body) {
        self.bodyMass = mass;
        btScalar bodyMass = mass;
        btVector3 bodyInertia;
        self.shape->calculateLocalInertia(bodyMass, bodyInertia);
        
        self.body->setMassProps(mass, bodyInertia);
        self.body->updateInertiaTensor();
    }
}

-(void)setVelocity:(vec3)velocity{
    if (self.body) {
        btVector3 vector = btVector3(velocity.x, velocity.y, velocity.z);
        self.body->setLinearVelocity(vector);
    }
}

#pragma mark - Model

-(void)generateShader{
    if (ShadI.animatedModelShader == 0) {
        ShadI.animatedModelShader = makeShader(@"animatedModel",
                                               @{@(ATTRIBUTE_POSITION): @"inPosition",
                                                 @(ATTRIBUTE_NORMAL): @"inNormal",
                                                 @(ATTRIBUTE_UV): @"inTexcoord",
                                                 @(ATTRIBUTE_TANGENT): @"inTangent",
                                                 @(ATTRIBUTE_BONE_IDS): @"inBoneIds",
                                                 @(ATTRIBUTE_BONE_WEIGHTS): @"inWeights",});
    }
    
    // модель
    _mvpMatrixLocation = glGetUniformLocation(ShadI.animatedModelShader, "u_mvpMatrix");
    _mvMatrixLocation = glGetUniformLocation(ShadI.animatedModelShader, "u_mvMatrix");
    _projMatrixLocation = glGetUniformLocation(ShadI.animatedModelShader, "u_projectionMatrix");
    _viewMatrixLocation =  glGetUniformLocation(ShadI.animatedModelShader, "u_viewMatrix");
    _modelMatrixLocation =  glGetUniformLocation(ShadI.animatedModelShader, "u_modelMatrix");
    _inShadowMatrixLocation =  glGetUniformLocation(ShadI.animatedModelShader, "u_toShadowMapMatrix");
    _lightPosLocation = glGetUniformLocation(ShadI.animatedModelShader, "u_cameraSpaceLightPos");
    _modelTextureLocation = glGetUniformLocation(ShadI.animatedModelShader, "u_texture");
    _shadowMapTextureLocation = glGetUniformLocation(ShadI.animatedModelShader, "u_shadowMapTexture");
    _normalsTextureLocation = glGetUniformLocation(ShadI.animatedModelShader, "u_normalsTexture");
    // кости
    for (int i = 0; i < MAX_BONES_COUNT; i++) {
        NSString* name = [NSString stringWithFormat:@"u_bonesTransforms[%d]", i];
        _bonesLocations[i] = glGetUniformLocation(ShadI.animatedModelShader, [name cStringUsingEncoding:NSASCIIStringEncoding]);
    }
}

-(void)updateBoneTransforms{
    // трансформы костей
    float runningTime = GlobI.timeFromStart;
    [self boneTransform:runningTime transforms:_resultBonesTransforms];
}

-(void)renderModelFromCamera:(Camera*)cameraObj light:(LightObject*)light toShadow:(BOOL)toShadowMap customProj:(const mat4*)customProj{
    [self updateBoneTransforms];
    [self updatePhysicsBody];
    
    // обновляем матрицу модели (ОБРАТНЫЙ ПОРЯДОК)
    mat4 modelMat = [self modelTransformMatrix];
    
    // вид из точки света
    mat4 shadowCamera = lookAt(light.lightPos, light.lightTargetPos, vec3(0.0, 1.0, 0.0));
    
    // камера вида
    mat4 camera;
    if (toShadowMap == FALSE) {
        camera = [cameraObj cameraMatrix];
    }else{
        camera = shadowCamera;
    }
    
    // проекция
    mat4 projection;
    if (customProj) {
        projection = *customProj;
    }else{
        projection = [self projectionMatrix];
    }
    
    mat4 mv = camera * modelMat;
    mat4 mvp = projection * mv;
    
    if ([self isVisible:mvp] == FALSE) {
        return;
    }
    
    mat4 shadowMvp = projection * shadowCamera * modelMat;
    
    // вектор света
    mat4 lightTranslate = translate(mat4(1.0), light.lightPos);
    vec3 cameraSpaceLightPos = vec3([cameraObj cameraMatrix] * vec4(light.lightPos, 1.0));
    
    // включаем шейдер для отрисовки
    [StatesI useProgramm:ShadI.animatedModelShader];
    
    // помещаем матрицу модельвидпроекция в шейдер (указываем)
    [StatesI setUniformMat4:_mvpMatrixLocation val:mvp];
    [StatesI setUniformMat4:_mvMatrixLocation val:mv];
    [StatesI setUniformMat4:_modelMatrixLocation val:modelMat];
    [StatesI setUniformMat4:_viewMatrixLocation val:camera];
    [StatesI setUniformMat4:_projMatrixLocation val:projection];
    [StatesI setUniformMat4:_inShadowMatrixLocation val:shadowMvp];
    [StatesI setUniformVec3:_lightPosLocation val:cameraSpaceLightPos];
    // кости
    for(uint i = 0; i < _resultBonesTransforms.size(); i++){
        mat4 transform = _resultBonesTransforms[i];
        [StatesI setUniformMat4:_bonesLocations[i] val:transform];
    }
    
    // включаем объект аттрибутов вершин
    [StatesI bindVAO:_vao];
    
    for(int i = 0; i < _entries.size(); i++){
        const uint materialIndex = _entries[i].materialIndex;
        assert(materialIndex < _textures.size());
        
        // текстуры
        if (toShadowMap == FALSE) {
            if (_textures[materialIndex]) {
                // текстура модели
                [StatesI setUniformInt:_modelTextureLocation val:0];
                [StatesI activateTexture:GL_TEXTURE0 type:GL_TEXTURE_2D texId:_textures[materialIndex]];
            }
            if (_normalTextures[materialIndex]) {
                // текстура тени
                [StatesI setUniformInt:_normalsTextureLocation val:1];
                [StatesI activateTexture:GL_TEXTURE1 type:GL_TEXTURE_2D texId:_normalTextures[materialIndex]];
            }
            // текстура тени
            [StatesI setUniformInt:_shadowMapTextureLocation val:2];
            [StatesI activateTexture:GL_TEXTURE2 type:GL_TEXTURE_2D texId:GlobI.shadowMapTexture];
        }
        
        glDrawElementsBaseVertex(GL_TRIANGLES, _entries[i].numIndexes, GL_UNSIGNED_INT,
                                 (void*)(sizeof(uint) * _entries[i].baseIndex), _entries[i].baseVertex);
    }
}

-(void)dealloc{
    delete self.shape;
    delete self.body->getMotionState();
    delete self.body;
    
    // TODO: удаление текстур
    [super dealloc];
}

@end