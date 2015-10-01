precision highp float;

in vec4  inPosition;
in vec3  inNormal;
in vec2  inTexcoord;
in vec3  inTangent;

uniform mat4 u_mvpMatrix;
uniform mat4 u_mvMatrix;
uniform mat4 u_projectionMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_modelMatrix;
uniform mat4 u_toShadowMapMatrix;
uniform vec3 u_cameraSpaceLightPos;

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
    tangent = normalize(tangent - normal * dot(tangent, normal));
    vec3 binormal = normalize(cross(tangent, normal));
    if (dot(cross(normal, tangent), binormal) < 0.0f){
        tangent = tangent * -1.0f;
    }
    tbn = mat3(tangent, binormal, normal);
}

void main (void) {
	gl_Position	= u_mvpMatrix * vec4(inPosition.xyz, 1.0);
    
    // направление к свету
    vec3 cameraSpacePos = vec3(u_mvMatrix * inPosition);
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
    shadowSpacePos = u_toShadowMapMatrix * inPosition;
}
