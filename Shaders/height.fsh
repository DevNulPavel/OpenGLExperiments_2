

in vec2 texCoord;
in vec3 normal;
in vec3 toLightVec;

uniform sampler2D u_texture;

out vec4 fragColor;


void main (void) {
    // диффузный фактор света
    float lightPower = max(dot(normal, toLightVec), 0.0);
    
    // результат
    vec4 textureColor = texture(u_texture, texCoord, 0.0);

    fragColor = textureColor * lightPower;
}