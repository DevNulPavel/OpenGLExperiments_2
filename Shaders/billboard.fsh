in vec2 texCoord;
uniform sampler2D u_texture;
out vec4 fragColor;

void main (void) {
    fragColor = texture(u_texture, texCoord, 0.0);
    fragColor.rgb *= fragColor.a;
    
    if (fragColor.a == 0) {
        discard;
    }
}