#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>

#import "modelUtil.h"
#import "imageUtil.h"

@interface GLEssentialsGLView : NSOpenGLView {
	CVDisplayLinkRef displayLink;
    NSTimer* _physicsTimer;
    double _lastDrawTime;
    NSTextField* _textField;
}

-(void)keyUp:(NSEvent *)theEvent;
-(void)keyDown:(NSEvent *)event;
-(void)mouseMoved:(NSEvent *)theEvent;

@end
