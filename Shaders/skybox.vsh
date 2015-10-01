in vec3  inPosition;
uniform mat4 u_modelViewProj;
out vec3 texCoord;

void main (void) {
    vec4 resultPosition = u_modelViewProj * vec4(inPosition, 1.0);
//	gl_Position	= resultPosition.xyww;  // специально, чтобы скай был за всеми моделями и не участвовал в z-буффере??
	gl_Position	= resultPosition;
    texCoord = inPosition;
}
