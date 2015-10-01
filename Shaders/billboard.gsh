layout(points) in;      // входные данные - точки
layout(triangle_strip) out; // выходные данные - цепочки треугольников
layout(max_vertices = 4) out;   // максимум 4ре вершины

uniform mat4 u_model;
uniform mat4 u_view;
uniform mat4 u_proj;
uniform vec3 u_cameraPosWorld;

out vec2 texCoord;

void main (void) {
	vec3 positionWorld = (u_model * gl_in[0].gl_Position).xyz;
    vec3 toCameraVecWorld = normalize(u_cameraPosWorld - positionWorld);
    vec3 upVec = vec3(0.0, 1.0, 0.0);
    vec3 rightVecWorld = normalize(cross(toCameraVecWorld, upVec));   // правило левой руки
//    upVec = normalize(cross(toCameraVecWorld, rightVecWorld));          // вычисляем новый вектор вверх (убрать чтобы не крутилось вверх вниз)

    mat4 mvp = u_proj * u_view * u_model;
    vec3 originPos = gl_in[0].gl_Position.xyz;
    vec3 position;

    // левый нижний угол квадрата
    position = originPos - rightVecWorld - upVec;
    gl_Position = mvp * vec4(position, 1.0);
    texCoord = vec2(0.0, 0.0);
    EmitVertex();
    
    // левый верхний угол
    position = originPos - rightVecWorld + upVec;
    gl_Position = mvp * vec4(position, 1.0);
    texCoord = vec2(0.0, 1.0);
    EmitVertex();

    // правый нижний
    position = originPos + rightVecWorld - upVec;
    gl_Position = mvp * vec4(position, 1.0);
    texCoord = vec2(1.0, 0.0);
    EmitVertex();
    
    // правый верхний
    position = originPos + rightVecWorld + upVec;
    gl_Position = mvp * vec4(position, 1.0);
    texCoord = vec2(1.0, 1.0);
    EmitVertex();

    EndPrimitive();
}
