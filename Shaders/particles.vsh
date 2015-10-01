
in vec3  inPosition;
uniform mat4 u_mvp;
uniform float u_time;
out vec3 color;

void main (void) {
    vec3 convertedPos = sin(inPosition * exp(inPosition) * cos(inPosition.x + u_time / 8.0) * sin(inPosition.z + u_time*1.5) * cos(inPosition.y - u_time/5.0) * 5.0);
    gl_PointSize = length(convertedPos);    // чем дальше от центра, тем больше размер
	gl_Position	= u_mvp * vec4(convertedPos, 1.0);
    
    color = vec3(1.0) - vec3(abs(convertedPos.y), abs(convertedPos.z), abs(convertedPos.x)) + vec3(0.5, 0.4, 0.3);
}
