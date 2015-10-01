#ifdef GL_ES
precision highp float;
#endif

in vec3  inPosition;
in vec2  inTexCoord;

out vec2 texCoord;

void main (void) {
	gl_Position	= vec4(inPosition, 1.0);
    
    texCoord = inTexCoord;
}
