#import <glm.hpp>
#import <ext.hpp>
#import "Camera.h"
#import "LightObject.h"
#import "GlobalValues.h"

using namespace glm;

@interface RenderObject: NSObject{
}

@property(nonatomic, assign) vec3 modelPos;
@property(nonatomic, assign) quat rotateQuat;
@property(nonatomic, assign) float scale;
@property(nonatomic, assign) BoudndingBox boundBox;

-(void)renderModelFromCamera:(Camera*)cameraObj light:(LightObject*)light toShadow:(BOOL)toShadowMap customProj:(const mat4*)customProj;
-(mat4)modelTransformMatrix;
-(mat4)projectionMatrix;
-(BOOL)isVisible:(const mat4&)mvp;
-(BOOL)isVisibleFromCamera:(Camera*)cameraObj;

@end

