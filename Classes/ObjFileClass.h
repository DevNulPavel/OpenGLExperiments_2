//
//  ObjFileModelClass.h
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 11.04.15.
//
//

#import <Foundation/Foundation.h>
#import "glm.hpp"
#import "ext.hpp"
#import <vector>
#import <string>
#import <fstream>
#import <sstream>
#import <vector>

using namespace glm;

class Model {
private:
    std::vector<vec4> verts_;
    std::vector<vec2> uvCoord_;
    std::vector<vec3> normales_;
    std::vector<std::vector<int> > vertexIndexes_;
    std::vector<std::vector<int> > textureIndexes_;
    std::vector<std::vector<int> > normalIndexes_;
public:
    Model(const char *filename);
    ~Model();
    
    // вершины - колво
    int vertsCount();
    int uvCoordsCount();
    int normalesCount();
    // индексы - кол-во
    int trianglesCount();
    
    // векторы индексов
    std::vector<int> vertexIndexes(int idx);
    std::vector<int> textureIndexes(int idx);
    std::vector<int> normalIndexes(int idx);
    // вершины
    vec4 vert(int i);
    vec2 uvCoord(int i);
    vec3 normal(int i);
};
