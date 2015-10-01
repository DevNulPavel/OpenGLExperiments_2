
in vec2 texCoord;

uniform sampler2D u_heightMap;
uniform float u_scaleFactor;
uniform float u_invTexSize;

out vec4 fragColor;
out vec4 fragColor2;
out vec4 fragColor3;

void main (void) {
    
    // судя по всему - вычисление нормали
    vec4 h = texture(u_heightMap, texCoord);
    vec4 h2 = texture(u_heightMap, vec2(texCoord.s, texCoord.t + u_invTexSize));
    vec4 h3 = texture(u_heightMap, texCoord + vec2(u_invTexSize, u_invTexSize));
    h.xy = vec2(0.0, 0.0);
    h2.xy = vec2(0.0, 1.0);
    h3.xy = vec2(1.0, 1.0);
    vec4 d1, d2;
    d1 = h2 - h;
    d2 = h3 - h;
    vec3 n = cross(d1.xyz, d2.xyz);

    // считаем позицию
    vec3 pos;
    pos.xy = (texCoord.st - vec2(0.5, 0.5)) * 2.0;
    pos.z = h.z * u_scaleFactor;
    
    // инверт по вертикали
    pos = vec3(pos.x, 1.0 - pos.y, pos.z);
    
    // сохраняем данные о позиции, нормали и текстурных координатах в текстуры
    fragColor = vec4(pos, 1.0);
    fragColor2 = vec4(-n, 1.0);
    fragColor3 = vec4(texCoord, 0.0, 0.0);
}