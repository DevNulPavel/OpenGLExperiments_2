#ifdef GL_ES
precision highp float;
#endif

in vec4  inPosition;
in vec3  inNormal;
in vec2  inTexcoord;
in vec3  inTangent;

uniform mat4 u_projectionMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_modelMatrix;
uniform vec3 u_glSpaceCameraPos;
uniform mat4 u_lengthCorrection;

out vec2 texCoord;
out vec3 fromCameraVec;
out mat3 tbn;
out vec3 normal;

void calcTBN(){
    // нормаль
    vec3 normal = normalize(u_modelMatrix * vec4(inNormal, 0.0)).xyz;
    vec3 tangent = normalize(u_modelMatrix * vec4(inTangent, 0.0)).xyz;
    tangent = normalize(tangent - normal * dot(tangent, normal));
    vec3 binormal = normalize(cross(tangent, normal));
    if (dot(cross(normal, tangent), binormal) < 0.0f){
        tangent = tangent * -1.0f;
    }
    tbn = mat3(tangent, binormal, normal);
}

void main (void) {
	gl_Position	= u_projectionMatrix * u_viewMatrix * u_modelMatrix * vec4(inPosition.xyz, 1.0);
    
    vec3 worldSpacePos = vec3(u_modelMatrix * u_lengthCorrection * inPosition);
    
    // направление к камере
    fromCameraVec = normalize(worldSpacePos - u_glSpaceCameraPos);
    
    // матрица перехода в тангенциальное пространство
    calcTBN();
    
    // нормаль
    normal = mat3(u_modelMatrix) * inNormal;
    normal = normalize(normal);
    
    // текст коорд
    texCoord = inTexcoord;
}
