in vec3  inPosition;
in vec2  inTexCoord;

uniform mat4 u_mvp;

out vec2 texCoord;

void main (void) {
	gl_Position	= u_mvp * vec4(inPosition, 1.0);
    
    texCoord = inTexCoord;
}
