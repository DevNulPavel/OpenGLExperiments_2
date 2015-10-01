//
#ifdef GL_ES
precision highp float;
#endif


in vec2 texCoord;
in vec3 fromCameraVec;
in mat3 tbn;
in vec3 normal;
uniform samplerCube u_cubemapTexture;
uniform sampler2D u_texture;
uniform sampler2D u_normalsTexture;
out vec4 fragColor;


vec3 calcBumpedNormal() {
    vec3 textureNormal = (texture(u_normalsTexture, texCoord, 0.0).xyz - 0.5)*2.0;
    vec3 newNormal = tbn * textureNormal;
    newNormal = normalize(newNormal);
    return newNormal;
}

void main (void) {
    // нормаль
    vec3 resnormal = calcBumpedNormal();
    
    // отражение (вектор домножается на обратную матрицу, тк нужно транформировать кубкарту в другую сторону)
//    vec3 reflectVector = normalize(reflect(fromCameraVec, resnormal));
    vec3 reflectVector = normalize(refract(fromCameraVec, resnormal,  1.0 / 1.05));
    vec4 skyColor = texture(u_cubemapTexture, reflectVector) * 1.0;
    
    vec4 textureColor = texture(u_texture, texCoord) * 0.0;
    
    // результат
    fragColor = textureColor + skyColor;
}