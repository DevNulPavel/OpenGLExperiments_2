precision highp float;


in vec2 texCoord;
in vec3 toLightVec;
in vec3 toCameraVec;
in mat3 tbn;
in vec3 normal;
in vec4 shadowSpacePos;
uniform sampler2D u_texture;
uniform sampler2D u_shadowMapTexture;
uniform sampler2D u_normalsTexture;
out vec4 fragColor;


vec3 calcBumpedNormal() {
    vec3 textureNormal = (texture(u_normalsTexture, texCoord, 0.0).xyz - 0.5)*2.0;
    vec3 newNormal = tbn * textureNormal;
    newNormal = normalize(newNormal);
    return newNormal;
}

float shadowCoeff(){
    vec3 projCoords = shadowSpacePos.xyz / shadowSpacePos.w;
    vec2 UVCoords;
    UVCoords.x = 0.5 * projCoords.x + 0.5;
    UVCoords.y = 0.5 * projCoords.y + 0.5;
    float z = 0.5 * projCoords.z + 0.5;
    float depth = texture(u_shadowMapTexture, UVCoords, 0.0).x;
    
    if (depth < (z - 0.00005)){
        return 0.6;
    }
    return 1.0;
}

void main (void) {
    // нормаль
    vec3 resnormal = calcBumpedNormal();
    
    // сила света
    float lightPower = 0.0;
    
    // диффузный
    float diffuseFactor = max(dot(toLightVec, resnormal), 0.0) * 1.5;
    lightPower += diffuseFactor;
    
    // тень
    float shadowVal = shadowCoeff();
    lightPower *= shadowVal;
    
    // блики
    if (shadowVal > 0.5) {
        vec3 reflectLightVector = normalize(reflect(-toLightVec, resnormal));     // вычисляем вектор отраженного света для пикселя
        float specFactor = max(dot(toCameraVec, reflectLightVector), 0.0);      // вычисляем насколкьо сильно совпадают вектара отражения и направления на камеру
        specFactor = pow(specFactor, 12.0)*1.4;
        lightPower += specFactor;
    }
    
    // результат
    vec4 textureColor = texture(u_texture, texCoord, 0.0);
    fragColor = textureColor * lightPower;
}