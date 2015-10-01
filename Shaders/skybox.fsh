in vec3 texCoord;
uniform samplerCube u_cubemapTexture;
out vec4 fragColor;

void main (void) {
    fragColor = texture(u_cubemapTexture, texCoord, 0.0);
}