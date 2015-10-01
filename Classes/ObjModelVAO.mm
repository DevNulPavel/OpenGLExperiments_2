//
//  ObjModel.m
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 10.04.15.
//
//

#import "ObjModelVAO.h"
#import "glm.hpp"
#import "ext.hpp"
#import <vector>
#import <iostream>
#import <string>
#import <fstream>
#import <sstream>
#import <vector>
#import "vectorUtil.h"
#import "VAOCreate.h"
//#import "ObjFileClass.h"
#import <assimp/Importer.hpp>
#import <assimp/scene.h>
#import <assimp/postprocess.h>
#import <map>

using namespace glm;

struct VAOInfo{
    int vaoId;
    int elementsCount;
    vector<Buffer> buffers;
    BoudndingBox box;
    VAOInfo(){
        vaoId = -1;
        elementsCount = -1;
    }
};

map<string, VAOInfo> cachedVaos;


GLuint buildObjVAO(NSString* filename, uint *elementsCount){
    vector<Buffer> vec;
    BoudndingBox box;
    return buildObjVAO(filename, elementsCount, vec, TRUE, box);
}

GLuint buildObjVAO(NSString* filename, uint *elementsCount, BoudndingBox& box){
    vector<Buffer> vec;
    return buildObjVAO(filename, elementsCount, vec, TRUE, box);
}

GLuint buildObjVAO(NSString* filename, uint *elementsCount, vector<Buffer>& buffers, BOOL withCache){
    BoudndingBox box;
    return buildObjVAO(filename, elementsCount, buffers, withCache, box);
}

GLuint buildObjVAO(NSString* filename, uint *elementsCount, vector<Buffer>& buffers, BOOL withCache, BoudndingBox& box){
    if (withCache) {
        string key = string([filename cStringUsingEncoding:NSASCIIStringEncoding]);
        if (cachedVaos[key].vaoId >= 0) {
            const VAOInfo& info = cachedVaos[key];
            
            *elementsCount = info.elementsCount;
            buffers = info.buffers;
            int vaoId = info.vaoId;
            box = info.box;
            return vaoId;
        }
    }
    
    Assimp::Importer importer;
    
    NSString* filePathName = [[NSBundle mainBundle] pathForResource:filename ofType:@"obj"];
    const char* cPath = [filePathName cStringUsingEncoding:NSASCIIStringEncoding];
    const aiScene* scene = importer.ReadFile(cPath, aiProcess_ValidateDataStructure | aiProcess_Triangulate | aiProcess_CalcTangentSpace | aiProcess_FlipUVs | aiProcess_OptimizeMeshes);
    
    assert(scene != nil);
    
    uint vertsCount = 0;
    uint indexesCount = 0;
    for (int i = 0; i < scene->mNumMeshes; i++) {
        const aiMesh* mesh = scene->mMeshes[i];
        vertsCount += mesh->mNumVertices;
        indexesCount += mesh->mNumFaces*3;
    }
    
    // буффер вершин
    uint verticesArraySize = 4 * vertsCount;
    GLfloat vertices[verticesArraySize];
    
    // буффер вершин
    uint normalsArraySize = 3 * vertsCount;
    GLfloat normals[normalsArraySize];
    
    // буффер текстурных координат
    uint uvArraySize = 2 * vertsCount;
    GLfloat uvs[uvArraySize];
    
    // буффер тангенсов координат
    uint tangentArraySize = 3 * vertsCount;
    GLfloat tangents[tangentArraySize];
    
    // буффер индексов
    uint indexesArraySize = indexesCount;
    GLuint indexes[indexesArraySize];
    
    *elementsCount = indexesCount;
    
    uint vertsOffset = 0;
    uint facesOffset = 0;
    vec3 maximum;
    vec3 minimum;
    for (uint i = 0; i < scene->mNumMeshes; i++) {
        const aiMesh* mesh = scene->mMeshes[i];

        for (uint j = 0; j < mesh->mNumVertices; j++) {
            aiVector3D aiPos = mesh->HasPositions() ? mesh->mVertices[j] : aiVector3D(0.0f, 0.0f, 0.0f);
            aiVector3D aiNormal = mesh->mNormals[j];
            aiVector3D aiUVCoord = mesh->HasTextureCoords(0) ? mesh->mTextureCoords[0][j] : aiVector3D(0.0f, 0.0f, 0.0f);
            aiVector3D aiTangens = mesh->mTangents[j];
            
            vec4 vertex(aiPos.x, aiPos.y, aiPos.z, 1.0);
            memcpy(&vertices[vertsOffset + j*4], &vertex, sizeof(GLfloat)*4);
            
            vec3 normal(aiNormal.x, aiNormal.y, aiNormal.z);
            memcpy(&normals[vertsOffset + j*3], &normal, sizeof(GLfloat)*3);
            
            vec2 uv(aiUVCoord.x, aiUVCoord.y);
            memcpy(&uvs[vertsOffset + j*2], &uv, sizeof(GLfloat)*2);
            
            vec3 tangen(aiTangens.x, aiTangens.y, aiTangens.z);
            memcpy(&tangents[vertsOffset + j*3], &tangen, sizeof(GLfloat)*3);
            
            // просчет баунд бокса
            float maxX = MAX(vertex.x, maximum.x);
            float maxY = MAX(vertex.y, maximum.y);
            float maxZ = MAX(vertex.z, maximum.z);
            maximum = vec3(maxX, maxY, maxZ);
            float minX = MIN(vertex.x, minimum.x);
            float minY = MIN(vertex.y, minimum.y);
            float minZ = MIN(vertex.z, minimum.z);
            minimum = vec3(minX, minY, minZ);
        }
        // индексы
        for (int j = 0; j < mesh->mNumFaces; j++) {
            aiFace face = mesh->mFaces[j];
            assert(face.mNumIndices == 3);
            
            GLuint index1 = face.mIndices[0];
            memcpy(&indexes[facesOffset + j*3 + 0], &index1, sizeof(GLuint));
            GLuint index2 = face.mIndices[1];
            memcpy(&indexes[facesOffset + j*3 + 1], &index2, sizeof(GLuint));
            GLuint index3 = face.mIndices[2];
            memcpy(&indexes[facesOffset + j*3 + 2], &index3, sizeof(GLuint));
        }
        vertsOffset += mesh->mNumVertices;
        facesOffset += mesh->mNumFaces;
    }
    
    // баундинг бокс
    box.leftBotomNear = vec3(minimum.x, minimum.y, minimum.z);
    box.rightBotomNear = vec3(maximum.x, minimum.y, minimum.z);
    box.leftTopNear = vec3(minimum.x, maximum.y, minimum.z);
    box.rightTopNear = vec3(maximum.x, maximum.y, minimum.z);
    
    box.leftBotomFar = vec3(minimum.x, minimum.y, maximum.z);
    box.rightBotomFar = vec3(maximum.x, minimum.y, maximum.z);
    box.leftTopFar = vec3(minimum.x, maximum.y, maximum.z);
    box.rightTopFar = vec3(maximum.x, maximum.y, maximum.z);
    
    
//    // тангенс
//    for (int i = 0; i < vertsCount; i += 3) {
//        vec3 v0;
//        memcpy(&v0, &(vertices[i*4+0*4]), 3*sizeof(GLfloat));
//        vec3 v1;
//        memcpy(&v1, &(vertices[i*4+1*4]), 3*sizeof(GLfloat));
//        vec3 v2;
//        memcpy(&v2, &(vertices[i*4+2*4]), 3*sizeof(GLfloat));
//        
//        vec2 uv0;
//        memcpy(&uv0, &(uvs[i*2+0*2]), 2*sizeof(GLfloat));
//        vec2 uv1;
//        memcpy(&uv1, &(uvs[i*2+1*2]), 2*sizeof(GLfloat));
//        vec2 uv2;
//        memcpy(&uv2, &(uvs[i*2+2*2]), 2*sizeof(GLfloat));
//        
//        vec3 delta0 = v1 - v0;
//        vec3 delta1 = v2 - v0;
//        
//        vec2 deltaUV0 = uv1 - uv0;
//        vec2 deltaUV1 = uv2 - uv0;
//        
//        float divValue = (deltaUV0.x * deltaUV1.y - deltaUV0.y * deltaUV1.x);
//        float r = 1.0f / divValue;
//        
//        vec3 tangent;
//        tangent.x = (delta0.x * deltaUV1.y - delta1.x * deltaUV0.y) * r;
//        tangent.y = (delta0.y * deltaUV1.y - delta1.y * deltaUV0.y) * r;
//        tangent.z = (delta0.z * deltaUV1.y - delta1.z * deltaUV0.y) * r;
//        
//        memcpy(&tangents[i*3 + 0*3], &tangent, sizeof(tangent));
//        memcpy(&tangents[i*3 + 1*3], &tangent, sizeof(tangent));
//        memcpy(&tangents[i*3 + 2*3], &tangent, sizeof(tangent));
//    }
    
    
    // создание 1го объекта
    GLuint vaoName;
    glGenVertexArrays(1, &vaoName);
    glBindVertexArray(vaoName);
    
    // создаем буффер вершин
    GLuint posBufferObj;
    glGenBuffers(1, &posBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferObj);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, 0);
    
    // создаем буффер объект для нормалей
    GLuint normalBufferObj;
    glGenBuffers(1, &normalBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, normalBufferObj);
    glBufferData(GL_ARRAY_BUFFER, sizeof(normals), normals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, 0);
    
    // создаем буффер объект для координат текстур
    GLuint texCoordBufferObj;
    glGenBuffers(1, &texCoordBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, texCoordBufferObj);
    glBufferData(GL_ARRAY_BUFFER, sizeof(uvs), uvs, GL_STATIC_DRAW);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, 0);
    
    // создаем буффер объект тангенса
    GLuint tangentBufferObj;
    glGenBuffers(1, &tangentBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, tangentBufferObj);
    glBufferData(GL_ARRAY_BUFFER, sizeof(tangents), tangents, GL_STATIC_DRAW);
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3, 3, GL_FLOAT, GL_FALSE, 0, 0);
    
    // индексы
    GLuint indexesBO;
    glGenBuffers(1, &indexesBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexesBO); // это массив индексов
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexes), indexes, GL_STATIC_DRAW);    // подгружаем на видеокарту
    
    // сохраняем буфферы
    buffers.push_back(Buffer(posBufferObj, sizeof(vertices)));
    buffers.push_back(Buffer(normalBufferObj, sizeof(normals)));
    buffers.push_back(Buffer(texCoordBufferObj, sizeof(uvs)));
    buffers.push_back(Buffer(tangentBufferObj, sizeof(tangents)));
    buffers.push_back(Buffer(indexesBO, sizeof(indexes)));
    
    VAOInfo info;
    info.vaoId = vaoName;
    info.elementsCount = *elementsCount;
    info.buffers = buffers;
    info.box = box;
    
    if (withCache) {
        string saveKey = string([filename cStringUsingEncoding:NSASCIIStringEncoding]);
        cachedVaos[saveKey] = info;
    }
    
    return vaoName;
}


