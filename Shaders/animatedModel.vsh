precision highp float;

in vec4  inPosition;
in vec3  inNormal;
in vec2  inTexcoord;
in vec3  inTangent;
in vec3  inBitangent;
in ivec4 inBoneIds;
in vec4  inWeights;

uniform mat4 u_mvpMatrix;
uniform mat4 u_mvMatrix;
uniform mat4 u_projectionMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_modelMatrix;
uniform mat4 u_toShadowMapMatrix;
uniform vec3 u_cameraSpaceLightPos;
uniform mat4 u_bonesTransforms[100];

out vec2 texCoord;
out vec3 toLightVec;
out vec3 toCameraVec;
out mat3 tbn;
out vec3 normal;
out vec4 shadowSpacePos;

void calcTBN(){
    // нормаль
    mat4 mv = u_mvMatrix;
    vec3 normal = normalize(mv * vec4(inNormal, 0.0)).xyz;
    vec3 tangent = normalize(mv * vec4(inTangent, 0.0)).xyz;
    vec3 bitangent = normalize(mv * vec4(inBitangent, 0.0)).xyz;
    // вычисление битангента
//    tangent = normalize(tangent - normal * dot(tangent, normal));
//    vec3 bitangent = normalize(cross(tangent, normal));
//    if (dot(cross(normal, tangent), bitangent) < 0.0f){
//        tangent = tangent * -1.0f;
//    }
    tbn = mat3(tangent, bitangent, normal);
}

void main (void) {
    // вычисляем костевую анимацию
    mat4 boneTransform = u_bonesTransforms[inBoneIds.x] * inWeights.x;
    boneTransform     += u_bonesTransforms[inBoneIds.y] * inWeights.y;
    boneTransform     += u_bonesTransforms[inBoneIds.z] * inWeights.z;
    boneTransform     += u_bonesTransforms[inBoneIds.w] * inWeights.w;
    // домножаем на костевую анимацию
    vec4 pos = boneTransform * inPosition;
    
	gl_Position	= u_mvpMatrix * pos;
    
    // направление к свету
    vec3 cameraSpacePos = vec3(u_mvMatrix * pos);
    toLightVec = normalize(u_cameraSpaceLightPos - cameraSpacePos);
    
    // направление к камере
    toCameraVec = normalize(-cameraSpacePos);   // мир вращается итак вокруг нас
    
    // матрица перехода в тангенциальное пространство
    calcTBN();
    
    // нормаль
    normal = transpose(inverse(mat3(u_mvMatrix))) * inNormal;
    normal = normalize(normal);
    
    // текст коорд
    texCoord = inTexcoord;
    
    // для карты теней
    shadowSpacePos = u_toShadowMapMatrix * pos;
}
