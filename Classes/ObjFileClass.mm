//
//  ObjFileModelClass.m
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 11.04.15.
//
//

#import "ObjFileClass.h"
#import <iostream>



Model::Model(const char *filename) : verts_(), uvCoord_(), normales_() {
    std::ifstream in;   // поток ввода данных
    in.open (filename, std::ifstream::in);  // откроем файл
    
    if (in.fail()) return;  // если не могли открыть - вырубаем
    
    std::string line;       // строка
    
    while (!in.eof()) {     // пока не кончится файл
        std::getline(in, line);     // читаем по одной линии
        std::istringstream iss(line.c_str());   // символьный поток, разделения по пробелам
        char trash = 0;
        
        // вершины
        if (!line.compare(0, 2, "v ")) {
            iss >> trash;       // закинем символ v в никуда
            vec4 v;
            v.w = 1.0;
            for (int i = 0; i < 3; i++) iss >> v[i];
            verts_.push_back(v);
        }
        // текстурные координаты (UV)
        else if (!line.compare(0, 3, "vt ")) {
            vec2 uvCoord;    // вектор в который будем пихать координаты текстуры (текстура двухмерная)
            iss >> trash;     // v в никуда
            iss >> trash;     // t в никуда
            for (int i = 0; i < 2; i++){
                iss >> uvCoord[i];
            }
            uvCoord_.push_back(uvCoord);
        }
        // нормали к вершинам
        else if (!line.compare(0, 3, "vn ")) {
            vec3 normal;    // вектор в который будем пихать координаты текстуры (текстура двухмерная)
            iss >> trash;    // v в никуда
            iss >> trash;    // n в никуда
            for (int i = 0; i < 3; i++){
                iss >> normal[i];
            }
            normales_.push_back(normal);
        }
        // треугольники (индексы), индексы текстуры, индексы нормалей
        else if (!line.compare(0, 2, "f ")) {
            
            std::vector<int> vertexIndexesItem;     // индексы треугольника
            std::vector<int> textureIndexesItem;    // индексы для текстуры
            std::vector<int> normalIndexesItem;    // индексы для текстуры
            
            int textureCoordIndex = 0;    // переменные для потокового парсинга
            int vertexIndex = 0;          // индекс
            int normalIndex = 0;          // индекс
            
            iss >> trash;           // символ f
            
            // парсим строчку на индексы
            // !!!!! АФРИКАНЕЦ !!!
            while (iss >> vertexIndex >> trash >> textureCoordIndex >> trash >> normalIndex) {
                // !!!!! ГОЛОВА !!!!!
                //            while (iss >> vertexIndex >> trash >> trash >> normalIndex) {
                vertexIndex--;              // в obj формате индекс начинается с 1цы
                vertexIndexesItem.push_back(vertexIndex);
                
                textureCoordIndex--;
                textureIndexesItem.push_back(textureCoordIndex);
                
                normalIndex--;
                normalIndexesItem.push_back(normalIndex);
            }
            
            vertexIndexes_.push_back(vertexIndexesItem);
            textureIndexes_.push_back(textureIndexesItem);
            normalIndexes_.push_back(normalIndexesItem);
        }
    }
    //    std::cerr << "# v# " << verts_.size() << " f# "  << vertexIndexes_.size() << std::endl;
}

Model::~Model() {
}

// индексы
int Model::trianglesCount() {
    return (int)vertexIndexes_.size();
}

// вершины
int Model::vertsCount() {
    return (int)verts_.size();
}

// геттеры
std::vector<int> Model::vertexIndexes(int idx) {
    return vertexIndexes_[idx];
}

std::vector<int> Model::textureIndexes(int idx) {
    return textureIndexes_[idx];
}

std::vector<int> Model::normalIndexes(int idx) {
    return normalIndexes_[idx];
}

vec4 Model::vert(int i) {
    return verts_[i];
}

vec2 Model::uvCoord(int i){
    return uvCoord_[i];
}

vec3 Model::normal(int i){
    return normales_[i];
}



