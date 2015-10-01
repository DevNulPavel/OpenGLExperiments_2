
in vec3  inPosition;
in vec3  inNormal;
in vec3  inTexcoord;

uniform mat4 u_mvpMatrix;
uniform mat4 u_mvMatrix;
uniform mat4 u_projectionMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_modelMatrix;
uniform vec3 u_lightPosWorld;

out vec2 texCoord;
out vec3 normal;
out vec3 toLightVec;

void main (void) {
	gl_Position	= u_mvpMatrix * vec4(inPosition, 1.0);
    
    vec3 worlSpaceVertexPos = mat3(u_modelMatrix) * inPosition;
    toLightVec = normalize(u_lightPosWorld - worlSpaceVertexPos);
    
    // нормаль
    normal = mat3(u_modelMatrix) * inNormal;
    normal = normalize(normal);
    
    // текст коорд
    texCoord = inTexcoord.xy;
}
