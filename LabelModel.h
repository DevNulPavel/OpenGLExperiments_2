//
//  Model3D.h
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "glUtil.h"
#import "RenderObject.h"
#import "glm.hpp"
#import "ext.hpp"

using namespace glm;

enum HorizontalAligh{
    LeftAlign = 0,
    CenterAlign = 1,
    RightAlign = 2,
};

enum VerticalAligh{
    TopAlign = 0,
    MiddleAlign = 1,
    BottomAlign = 2,
};


@interface LabelModel: RenderObject{
    NSString* _text;
    
    uint _width;
    uint _height;
        
    // модель
    GLint _modelVAO;
    GLint _modelElementsCount;
    
    // текстуры
    GLint _textTexture;
    
    // шейдер
    GLint _texureLocation;
    GLint _mvpLocation;
}

@property(nonatomic, assign) CGSize maxSize;
@property(nonatomic, retain) NSString* fontName;
@property(nonatomic, retain) NSString* text;
@property(nonatomic, assign) float fontSize;
@property(nonatomic, assign) HorizontalAligh horizontalAlign;
@property(nonatomic, assign) VerticalAligh verticalAlign;

-(id)initWithText:(NSString*)text fontSize:(float)fontSize;

@end
