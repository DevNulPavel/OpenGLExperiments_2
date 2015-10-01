in vec3  inPosition;
in vec3  inColor;
uniform mat4 u_mvp;
out vec3 color;

void main (void) {
	gl_Position	= u_mvp * vec4(inPosition, 1.0);
    color = inColor;
}
