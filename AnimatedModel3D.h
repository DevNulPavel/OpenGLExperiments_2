//
//  Model3D.h
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import <Foundation/Foundation.h>
#import "glUtil.h"
#import "RenderObject.h"
#import "glm.hpp"
#import "ext.hpp"
#import "Camera.h"
#import <vector>
#import <map>
#import <assimp/Importer.hpp>
#import <assimp/scene.h>
#import <assimp/postprocess.h>
#import "AnimatedModelStructs.h"
#import "btBulletCollisionCommon.h"
#import "btBulletDynamicsCommon.h"


using namespace glm;
using namespace std;

enum AttributeIndexes{
    ATTRIBUTE_POSITION = 0,
    ATTRIBUTE_NORMAL = 1,
    ATTRIBUTE_UV = 2,
    ATTRIBUTE_TANGENT = 3,
    ATTRIBUTE_BITANGENT = 4,
    ATTRIBUTE_BONE_IDS = 5,
    ATTRIBUTE_BONE_WEIGHTS = 6,
};
#define ATTRIBUTE_BUFFERS_COUNT 7

#define MAX_BONES_COUNT 100

@interface AnimatedModel3D: RenderObject{
    Assimp::Importer _importer;
    const aiScene* _scene;
    vec3 _minimum;
    vec3 _maximum;
    
    // инфа
    GLuint _vao;
    GLuint _buffers[ATTRIBUTE_BUFFERS_COUNT];
    vector<MeshEntry> _entries;
    vector<GLint> _textures;
    vector<GLint> _normalTextures;

    // фигура
    vector<vec4> _positions;
    vector<vec3> _normals;
    vector<vec2> _texCoords;
    vector<vec3> _tangents;
    vector<vec3> _bitangents;
    vector<VertexBoneData> _bones;
    vector<uint> _indexes;
    
    //кости
    map<string, uint> _boneMapping;
    uint _numBones;
    vector<BoneInfo> _boneInfos;
    mat4 _globalInverseTransform;
    vector<mat4> _resultBonesTransforms;
    
    // шейдер
    GLint _mvpMatrixLocation;
    GLint _mvMatrixLocation;
    GLint _projMatrixLocation;
    GLint _viewMatrixLocation;
    GLint _modelMatrixLocation;
    GLint _inShadowMatrixLocation;
    GLint _lightPosLocation;
    GLint _modelTextureLocation;
    GLint _shadowMapTextureLocation;
    GLint _normalsTextureLocation;
    GLint _bonesLocations[MAX_BONES_COUNT];
}

@property (nonatomic, assign) int curAnimationIndex;

@property (nonatomic, assign) btRigidBody* body;
@property (nonatomic, assign) btCollisionShape* shape;
@property (nonatomic, assign) float bodyMass;


-(id)initWithFilename:(NSString *)filename animIndex:(int)animIndex withBody:(BOOL)withBody;

-(void)addToPhysicsWorld;
-(void)removeFromPhysicsWorld;
-(void)setMass:(float)mass;
-(void)setVelocity:(vec3)velocity;

@end
