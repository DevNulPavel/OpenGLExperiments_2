//
#ifdef GL_ES
precision highp float;
#endif



in vec2 texCoord;
out vec4 fragColor;

uniform sampler2D u_texture;

void main (void) {
    float depth = texture(u_texture, texCoord, 0.0).x;
    depth = 1.0 - (1.0 - depth) * 50.0;
    fragColor = vec4(depth);
    
//    fragColor = texture(u_texture, texCoord);
}