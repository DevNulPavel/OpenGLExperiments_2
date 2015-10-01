in vec2 texCoord;
uniform sampler2D u_texture;
out vec4 fragColor;

void main (void) {
//    fragColor = vec4(texture(u_texture, texCoord).r, 0.0, 0.0, 1.0);
    vec2 newTexCoord = vec2(texCoord.x, 1.0 - texCoord.y);
    float alphaVal = texture(u_texture, newTexCoord).r;
    fragColor = vec4(0.0, 1.0, 0.0, 1.0) * alphaVal;
}