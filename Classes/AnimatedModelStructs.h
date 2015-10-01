//
//  AnimatedModelStructs.h
//  OSXGLEssentials
//
//  Created by DevNul on 14.04.15.
//
//

#ifndef OSXGLEssentials_AnimatedModelStructs_h
#define OSXGLEssentials_AnimatedModelStructs_h

#define INVALID_MATERIAL 0xFFFFFFFF
#define NUM_BONES_PER_VEREX 4

struct MeshEntry{
    uint numIndexes;
    uint baseVertex;
    uint baseIndex;
    uint materialIndex;
    MeshEntry(){
        numIndexes = 0;
        baseVertex = 0;
        baseIndex = 0;
        materialIndex = INVALID_MATERIAL;
    }
};

struct VertexBoneData{
    uint ids[NUM_BONES_PER_VEREX];
    float weights[NUM_BONES_PER_VEREX];
    VertexBoneData(){
        reset();
    }
    void reset(){
        memset(ids, 0, sizeof(ids));
        memset(weights, 0, sizeof(weights));
    }
    void addBoneData(uint boneId, float weight){
        for(uint i = 0; i < NUM_BONES_PER_VEREX; i++){
            if(weights[i] == 0.0){
                ids[i] = boneId;
                weights[i] = weight;
            }
        }
    }
};

struct BoneInfo{
    mat4 boneOffset;
    mat4 finalTransform;
    BoneInfo(){
        boneOffset = mat4(0.0);
        finalTransform = mat4(0.0);
    }
};

#endif
