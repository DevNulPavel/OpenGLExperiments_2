//
//  Model3D.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "LabelModel.h"
#import "GlobalValues.h"
#import "ObjModelVAO.h"
#import "TextureCreate.h"
#import "ShadersCache.h"
#import "GlobalValues.h"
#import "GLStatesCache.h"
#import "FrameBufferCreate.h"
#import "VAOCreate.h"


unsigned long nextPOT(unsigned long x)
{
    x = x - 1;
    x = x | (x >> 1);
    x = x | (x >> 2);
    x = x | (x >> 4);
    x = x | (x >> 8);
    x = x | (x >>16);
    return x + 1;
}


@implementation LabelModel

-(id)initWithText:(NSString*)text fontSize:(float)fontSize{
    if ((self = [super init])) {
        
        NSInteger maxWidth = 9999;
        NSInteger maxHeight = 9999;
        self.maxSize = CGSizeMake(maxWidth, maxHeight);
        self.fontName = @"Arial";
        self.fontSize = fontSize;
        _text = [text retain];
        
        _mvpLocation = -1;
        _texureLocation = -1;
        _textTexture = -1;
        
        self.horizontalAlign = CenterAlign;
        self.verticalAlign = BottomAlign;
        
        [self generateShader];
        [self updateTexture];
        [self makeVAO];
    }
    return self;
}


-(void)dealloc{
    self.fontName = nil;
    self.text = nil;
    // TODO: удаление текстур
    [super dealloc];
}

-(void)setText:(NSString *)text{
    if (_text) {
        [_text release];
    }
    _text = [text retain];
    [self updateTexture];
}

#pragma mark - Model

-(void)makeVAO{
    _modelVAO = spriteVAO(&_modelElementsCount);
}

-(void)removeTexture{
    if (_textTexture >= 0) {
        glDeleteTextures(1, (GLuint*)(&_textTexture));
        _textTexture = -1;
    }
}

-(void)updateTexture{
    
    [self removeTexture];
    
    NSFont* font = [NSFont fontWithName:self.fontName size:self.fontSize];
    if( !font ) {
        NSLog(@"WRONG");
        [self release];
    }
    
    NSDictionary* dict = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    
    NSAttributedString* stringWithAttributes = [[[NSAttributedString alloc] initWithString:self.text attributes:dict] autorelease];
    
    CGSize dim = NSSizeToCGSize([stringWithAttributes size]);
    
    NSAssert(stringWithAttributes, @"Invalid stringWithAttributes");
    
    // get nearest power of two
    NSSize POTSize = NSMakeSize(nextPOT(dim.width), nextPOT(dim.height));
    
    // Get actual rendered dimensions
    NSRect boundingRect = [stringWithAttributes boundingRectWithSize:NSSizeFromCGSize(dim) options:NSStringDrawingUsesLineFragmentOrigin];
    
    // Mac crashes if the width or height is 0
    if( POTSize.width == 0 )
        POTSize.width = 1;
    
    if( POTSize.height == 0)
        POTSize.height = 1;
    
    CGSize offset = CGSizeMake(0, POTSize.height - dim.height);
    
    //Alignment
    switch (self.horizontalAlign) {
        case LeftAlign: break;
        case CenterAlign: offset.width = (POTSize.width-boundingRect.size.width)/2.0f; break;
        case RightAlign: offset.width = POTSize.width-boundingRect.size.width; break;
    }
    switch (self.verticalAlign) {
        case TopAlign: offset.height += POTSize.height - boundingRect.size.height; break;
        case MiddleAlign: offset.height += (POTSize.height - boundingRect.size.height) / 2.0f; break;
        case BottomAlign: break;
        default: break;
    }
    
    CGRect drawArea = CGRectMake(offset.width, offset.height, boundingRect.size.width, boundingRect.size.height);
    
    //Disable antialias
    [[NSGraphicsContext currentContext] setShouldAntialias:NO];
    
    NSImage *image = [[NSImage alloc] initWithSize:POTSize];
    [image lockFocus];
    [[NSAffineTransform transform] set];
    
    [stringWithAttributes drawWithRect:NSRectFromCGRect(drawArea) options:NSStringDrawingUsesLineFragmentOrigin];
    
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect (0.0f, 0.0f, POTSize.width, POTSize.height)];
    [image unlockFocus];
    
    unsigned char *data = (unsigned char*) [bitmap bitmapData];  //Use the same buffer to improve the performance.
    
    NSUInteger textureSize = POTSize.width * POTSize.height;    
    unsigned char* dst = (unsigned char*)malloc(sizeof(unsigned char) * textureSize);
    for(int i = 0; i < textureSize; i++){
        dst[i] = data[i*4+3];					//Convert RGBA8888 to A8
    }
    data = dst;
    
    // создание текстуры
    glGenTextures(1, (GLuint*)(&_textTexture));
    glBindTexture(GL_TEXTURE_2D, _textTexture);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, POTSize.width, POTSize.height, 0, GL_RED, GL_UNSIGNED_BYTE, dst);

    glBindTexture(GL_TEXTURE_2D, 0);
    
    // сохраняем размеры
    _width = POTSize.width;
    _height = POTSize.height;
    if (_width == 0) {
        _width = 1;
    }
    if (_height == 0) {
        _height = 1;
    }
    
    free(dst);
    [bitmap release];
    [image release];
}

-(void)generateShader{
    // модель
    _texureLocation = glGetUniformLocation(ShadI.textShader, "u_texture");
    _mvpLocation = glGetUniformLocation(ShadI.textShader, "u_mvp");
}

-(void)renderModelFromCamera:(Camera*)cameraObj light:(LightObject*)light toShadow:(BOOL)toShadowMap customProj:(const mat4*)customProj{
    if (toShadowMap) {
        return;
    }
    
//    [StatesI enableState:GL_BLEND];
//    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    mat4 modelMat;
    modelMat = translate(modelMat, vec3(self.modelPos.x + _width/2, self.modelPos.y + _height/2, 0.0));
    modelMat = scale(modelMat, vec3(_width/2, _height/2, 1.0));
    
    mat4 proj;
    proj = ortho(0.0f, GlobI.viewWidth, 0.0f, GlobI.viewHeight, 0.0f, 1.0f);
    
    mat4 mvp = proj * modelMat;
    
    [StatesI useProgramm:ShadI.textShader];
    // трансформ
    [StatesI setUniformMat4:_mvpLocation val:mvp];
    // текстура
    [StatesI setUniformInt:_texureLocation val:0];
    [StatesI activateTexture:GL_TEXTURE0 type:GL_TEXTURE_2D texId:_textTexture];
    
    [StatesI bindVAO:_modelVAO];
    glDrawElements(GL_TRIANGLES, _modelElementsCount, GL_UNSIGNED_INT, 0);
    
//    [StatesI disableState:GL_BLEND];
}

@end