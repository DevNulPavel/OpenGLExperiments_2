//
//  VAOCreate.m
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 05.04.15.
//
//

#import "VAOCreate.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))


GLuint cubeVAO(int* elementsCount) {
    *elementsCount = 36;
    
    // создание 1го объекта
    GLuint vaoName;
    glGenVertexArrays(1, &vaoName);
    glBindVertexArray(vaoName);
    
    // создаем буффер вершин
    GLfloat cubeVertices[] = {
        // front
        -1.0, -1.0,  1.0,
        1.0, -1.0,  1.0,
        1.0,  1.0,  1.0,
        -1.0,  1.0,  1.0,
        // back
        -1.0, -1.0, -1.0,
        1.0, -1.0, -1.0,
        1.0,  1.0, -1.0,
        -1.0,  1.0, -1.0,
    };
    GLuint vertexBO;
    glGenBuffers(1, &vertexBO);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBO);         //  это массив вершин
    glBufferData(GL_ARRAY_BUFFER, sizeof(cubeVertices), cubeVertices, GL_STATIC_DRAW);  // подгружаем на видеокарту
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
    
    // создаем буффер вершин
    GLfloat color[] = {
        // front colors
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 1.0,
        1.0, 1.0, 1.0,
        // back colors
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0,
        0.0, 0.0, 1.0,
        1.0, 1.0, 1.0,
    };
    GLuint colorBO;
    glGenBuffers(1, &colorBO);
    glBindBuffer(GL_ARRAY_BUFFER, colorBO);         //  это массив вершин
    glBufferData(GL_ARRAY_BUFFER, sizeof(color), color, GL_STATIC_DRAW);  // подгружаем на видеокарту
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, 0);
    
    // создаем буффер индексов
    unsigned int indexes[] = {
        // front
        0, 1, 2,
        2, 3, 0,
        // top
        3, 2, 6,
        6, 7, 3,
        // back
        7, 6, 5,
        5, 4, 7,
        // bottom
        4, 5, 1,
        1, 0, 4,
        // left
        4, 0, 3,
        3, 7, 4,
        // right
        1, 5, 6,
        6, 2, 1,
    };
    GLuint indexesBO;
    glGenBuffers(1, &indexesBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexesBO); // это массив индексов
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexes), indexes, GL_STATIC_DRAW);    // подгружаем на видеокарту
    
    return vaoName;
}


GLuint particlesVAO(int* pointsCount) {
    float xCount = 15;
    float yCount = 15;
    float zCount = 15;
    float startX = -1.0;
    float endX = 1.0;
    float startY = -1.0;
    float endY = 1.0;
    float startZ = -1.0;
    float endZ = 1.0;
    float stepX = (endX - startX) / xCount;
    float stepY = (endY - startY) / yCount;
    float stepZ = (endZ - startZ) / zCount;
    
    *pointsCount = int(xCount * yCount * zCount);
    
    size_t pointsMemorySize = sizeof(GLfloat) * 3 * xCount * yCount * zCount;
    GLfloat* points = (GLfloat*)malloc(pointsMemorySize);
    memset(points, 0, pointsMemorySize);
    
    int i = 0;
    for (float x = 0; x < xCount; x += 1) {
        for (float y = 0; y < yCount; y += 1) {
            for (float z = 0; z < zCount; z += 1) {
                float curX = startX + stepX * x + randomFloat(-stepX/2.0, stepX/2.0);
                float curY = startY + stepY * y + randomFloat(-stepY/2.0, stepY/2.0);
                float curZ = startZ + stepZ * z + randomFloat(-stepZ/2.0, stepZ/2.0);
                
                points[i++] = curX;
                points[i++] = curY;
                points[i++] = curZ;
            }
        }
    }
    
    // создание 1го объекта
    GLuint vaoName;
    glGenVertexArrays(1, &vaoName);
    glBindVertexArray(vaoName);
    
    // создаем буффер вершин
    GLuint posBufferObj;
    glGenBuffers(1, &posBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferObj);
    glBufferData(GL_ARRAY_BUFFER, pointsMemorySize, points, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,		// индекс аттрибута в шейдере
                          3,	// из скольки элементов состоит (вершина из 3х значений)
                          GL_FLOAT,	// тип данных
                          GL_FALSE,				// данные не являются нормализованными
                          0, // шаг между отдельными элементами в байтах 3*sizeof(float)
                          0);	// данные с нулевым оффсетом
    
    free(points);
    
    return vaoName;
}

GLuint billboardVAO(std::vector<vec3> positions) {
    // создание 1го объекта
    GLuint vaoName;
    glGenVertexArrays(1, &vaoName);
    glBindVertexArray(vaoName);
    
    // создаем буффер вершин
    GLuint posBufferObj;
    glGenBuffers(1, &posBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferObj);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vec3) * positions.size(), &positions, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,		// индекс аттрибута в шейдере
                          3,	// из скольки элементов состоит (вершина из 3х значений)
                          GL_FLOAT,	// тип данных
                          GL_FALSE,				// данные не являются нормализованными
                          0, // шаг между отдельными элементами в байтах 3*sizeof(float)
                          0);	// данные с нулевым оффсетом
    GetGLError();
    
    return vaoName;
}

GLuint debugSpriteVAO(int* elementsCounter) {
    *elementsCounter = 6;
    
    GLfloat points[] = {0.7, -1.0, -1.0,
                        0.7, -0.7, -1.0,
                        1.0, -0.7, -1.0,
                        1.0, -1.0, -1.0};
    GLfloat texCoords[] = { 0.0, 0.0,
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0};
    GLuint indexes[] = {0, 3, 1,
        3, 2, 1};
    
    // создание 1го объекта
    GLuint vaoName;
    glGenVertexArrays(1, &vaoName);
    glBindVertexArray(vaoName);
    
    // создаем буффер вершин
    GLuint posBufferObj;
    glGenBuffers(1, &posBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferObj);
    glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,		// индекс аттрибута в шейдере
                          3,	// из скольки элементов состоит (вершина из 3х значений)
                          GL_FLOAT,	// тип данных
                          GL_FALSE,				// данные не являются нормализованными
                          3 * sizeof(GL_FLOAT), // шаг между отдельными элементами в байтах 3*sizeof(float)
                          BUFFER_OFFSET(0));	// данные с нулевым оффсетом
    
    
    // создаем буффер объект для нормалей
    GLuint texCoordName;
    glGenBuffers(1, &texCoordName);
    glBindBuffer(GL_ARRAY_BUFFER, texCoordName);
    glBufferData(GL_ARRAY_BUFFER, sizeof(texCoords), texCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,
                          2,
                          GL_FLOAT,
                          GL_FALSE,
                          2 * sizeof(GL_FLOAT),
                          BUFFER_OFFSET(0));
    
    // создание буффера индексов
    GLuint elementBufferName;
    glGenBuffers(1, &elementBufferName);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferName);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexes), indexes, GL_STATIC_DRAW);
    
    GetGLError();
    
    return vaoName;
}

GLuint spriteVAO(int* elementsCounter) {
    *elementsCounter = 6;
    
    GLfloat points[] = {-1.0, -1.0, 0.0,
                        -1.0, 1.0, 0.0,
                        1.0, 1.0, 0.0,
                        1.0, -1.0, 0.0};
    GLfloat texCoords[] = { 0.0, 0.0,
                            0.0, 1.0,
                            1.0, 1.0,
                            1.0, 0.0};
    GLuint indexes[] = {0, 3, 1,
                        3, 2, 1};
    
    // создание 1го объекта
    GLuint vaoName;
    glGenVertexArrays(1, &vaoName);
    glBindVertexArray(vaoName);
    
    // создаем буффер вершин
    GLuint posBufferObj;
    glGenBuffers(1, &posBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferObj);
    glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,		// индекс аттрибута в шейдере
                          3,	// из скольки элементов состоит (вершина из 3х значений)
                          GL_FLOAT,	// тип данных
                          GL_FALSE,				// данные не являются нормализованными
                          3 * sizeof(GL_FLOAT), // шаг между отдельными элементами в байтах 3*sizeof(float)
                          BUFFER_OFFSET(0));	// данные с нулевым оффсетом
    
    
    // создаем буффер объект для нормалей
    GLuint texCoordName;
    glGenBuffers(1, &texCoordName);
    glBindBuffer(GL_ARRAY_BUFFER, texCoordName);
    glBufferData(GL_ARRAY_BUFFER, sizeof(texCoords), texCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1,
                          2,
                          GL_FLOAT,
                          GL_FALSE,
                          2 * sizeof(GL_FLOAT),
                          BUFFER_OFFSET(0));
    
    // создание буффера индексов
    GLuint elementBufferName;
    glGenBuffers(1, &elementBufferName);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferName);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexes), indexes, GL_STATIC_DRAW);
    
    GetGLError();
    
    return vaoName;
}

GLuint skyboxVAO(int* elementsCounter) {
    *elementsCounter = 36;
    
    GLfloat points[] = {        // vert
        // front
        -1.0, -1.0,  1.0,
        1.0, -1.0,  1.0,
        1.0,  1.0,  1.0,
        -1.0,  1.0,  1.0,
        // top
        -1.0,  1.0,  1.0,
        1.0,  1.0,  1.0,
        1.0,  1.0, -1.0,
        -1.0,  1.0, -1.0,
        // back
        1.0, -1.0, -1.0,
        -1.0, -1.0, -1.0,
        -1.0,  1.0, -1.0,
        1.0,  1.0, -1.0,
        // bottom
        -1.0, -1.0, -1.0,
        1.0, -1.0, -1.0,
        1.0, -1.0,  1.0,
        -1.0, -1.0,  1.0,
        // left
        -1.0, -1.0, -1.0,
        -1.0, -1.0,  1.0,
        -1.0,  1.0,  1.0,
        -1.0,  1.0, -1.0,
        // right
        1.0, -1.0,  1.0,
        1.0, -1.0, -1.0,
        1.0,  1.0, -1.0,
        1.0,  1.0,  1.0,};
    GLuint indexes[] = {// front
        // front
        0,  1,  2,
        2,  3,  0,
        // top
        4,  5,  6,
        6,  7,  4,
        // back
        8,  9, 10,
        10, 11,  8,
        // bottom
        12, 13, 14,
        14, 15, 12,
        // left
        16, 17, 18,
        18, 19, 16,
        // right
        20, 21, 22,
        22, 23, 20,};
    
    // создание 1го объекта
    GLuint vaoName;
    glGenVertexArrays(1, &vaoName);
    glBindVertexArray(vaoName);
    
    // создаем буффер вершин
    GLuint posBufferObj;
    glGenBuffers(1, &posBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferObj);
    glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0,		// индекс аттрибута в шейдере
                          3,	// из скольки элементов состоит (вершина из 3х значений)
                          GL_FLOAT,	// тип данных
                          GL_FALSE,				// данные не являются нормализованными
                          0, // шаг между отдельными элементами в байтах 3*sizeof(float)
                          BUFFER_OFFSET(0));	// данные с нулевым оффсетом
    
    // создание буффера индексов
    GLuint elementBufferName;
    glGenBuffers(1, &elementBufferName);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferName);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexes), indexes, GL_STATIC_DRAW);
    
    GetGLError();
    
    return vaoName;
}

GLuint buildModelVAO(GLuint* elementsCounter, GLuint* elementsType, BoudndingBox& box) {
    NSString* filePathName = [[NSBundle mainBundle] pathForResource:@"demon" ofType:@"model"];
    demoModel* model = mdlLoadModel([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
    *elementsCounter = model->numElements;
    *elementsType = model->elementType;
    
    vec3 maximum;
    vec3 minimum;
    for (int i = 0; i < model->positionArraySize/sizeof(GLfloat)/4; i++) {
        // просчет баунд бокса
        float maxX = MAX(model->positions[i*4 + 0], maximum.x);
        float maxY = MAX(model->positions[i*4 + 1], maximum.y);
        float maxZ = MAX(model->positions[i*4 + 2], maximum.z);
        maximum = vec3(maxX, maxY, maxZ);
        float minX = MIN(model->positions[i*4 + 0], minimum.x);
        float minY = MIN(model->positions[i*4 + 1], minimum.y);
        float minZ = MIN(model->positions[i*4 + 2], minimum.z);
        minimum = vec3(minX, minY, minZ);
    }
    box.leftBotomNear = vec3(minimum.x, minimum.y, minimum.z);
    box.rightBotomNear = vec3(maximum.x, minimum.y, minimum.z);
    box.leftTopNear = vec3(minimum.x, maximum.y, minimum.z);
    box.rightTopNear = vec3(maximum.x, maximum.y, minimum.z);
    
    box.leftBotomFar = vec3(minimum.x, minimum.y, maximum.z);
    box.rightBotomFar = vec3(maximum.x, minimum.y, maximum.z);
    box.leftTopFar = vec3(minimum.x, maximum.y, maximum.z);
    box.rightTopFar = vec3(maximum.x, maximum.y, maximum.z);
    
    
    GLuint vaoName;
    glGenVertexArrays(1, &vaoName);
    glBindVertexArray(vaoName);
    
    // создаем буффер вершин
    GLuint posBufferObj;
    glGenBuffers(1, &posBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferObj);
    glBufferData(GL_ARRAY_BUFFER, model->positionArraySize, model->positions, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, model->positionSize, model->positionType, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    // создаем буффер объект для нормалей
    GLuint normalBufferObj;
    glGenBuffers(1, &normalBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, normalBufferObj);
    glBufferData(GL_ARRAY_BUFFER, model->normalArraySize, model->normals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, model->normalSize, model->normalType, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    
    // создаем буффер объект для координат текстур
    GLuint texCoordBufferObj;
    glGenBuffers(1, &texCoordBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, texCoordBufferObj);
    glBufferData(GL_ARRAY_BUFFER, model->texcoordArraySize, model->texcoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, model->texcoordSize, model->texcoordType, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    // создаем буффер объект тангенса
    GLuint tangentBufferObj;
    glGenBuffers(1, &tangentBufferObj);
    glBindBuffer(GL_ARRAY_BUFFER, tangentBufferObj);
    glBufferData(GL_ARRAY_BUFFER, model->tangentArraySize, model->tangent, GL_STATIC_DRAW);
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3, model->tangentSize, model->tangentType, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    
    // создание буффера индексов
    GLuint elementBufferObj;
    glGenBuffers(1, &elementBufferObj);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferObj);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, model->elementArraySize, model->elements, GL_STATIC_DRAW);
    
    // удаляем
    mdlDestroyModel(model);
    
    GetGLError();
    
    return vaoName;
}

void destroyVAO(GLuint vaoName){
    GLuint index;
    GLuint bufName;
    
    // включаем работу с объектом буффера вершин
    glBindVertexArray(vaoName);
    
    // удаляем все доступные подбуфферы
    for(index = 0; index < 16; index++) {
        glGetVertexAttribiv(index , GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
        
        if(bufName) {
            glDeleteBuffers(1, &bufName);
        }
    }
    
    // дергаем буффер индексов
    glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
    
    // уничтожаем, если есть
    if(bufName){
        glDeleteBuffers(1, &bufName);
    }
    
    // удаляем сам буффер аттрибутов
    glDeleteVertexArrays(1, &vaoName);
    
    GetGLError();
}