
#import "GLEssentialsGLView.h"
#import "OpenGLRenderer.h"

@interface GLEssentialsGLView (PrivateMethods)
- (void) initGL;
@end


@implementation GLEssentialsGLView

OpenGLRenderer* m_renderer;

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime {
	[self drawView];
	return kCVReturnSuccess;
}

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink,
									  const CVTimeStamp* now,
									  const CVTimeStamp* outputTime,
									  CVOptionFlags flagsIn,
									  CVOptionFlags* flagsOut, 
									  void* displayLinkContext) {
    CVReturn result = [(GLEssentialsGLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (void) awakeFromNib {
    // опенгл
    NSOpenGLPixelFormatAttribute attrs[] = {
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion4_1Core,    // используем опенгл 4.1
		0
	};
	
	NSOpenGLPixelFormat* pf = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
	if (!pf) {
		NSLog(@"No OpenGL pixel format");
	}
	   
    NSOpenGLContext* context = [[[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil] autorelease];
	CGLEnable([context CGLContextObj], kCGLCECrashOnRemovedFunctions);
	
    [self setPixelFormat:pf];
    [self setOpenGLContext:context];
}

- (void) prepareOpenGL {
	[super prepareOpenGL];
	
	[self initGL];
	
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);
	
	// Set the display link for the current renderer
	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	
	// Activate the display link
	CVDisplayLinkStart(displayLink);
	
	// Register to be notified when the window closes so we can stop the displaylink
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowWillClose:)
												 name:NSWindowWillCloseNotification
											   object:[self window]];
    
    // таймер для физики в главном потоке
    _physicsTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0
                                                     target:self
                                                   selector:@selector(updatePhysics)
                                                   userInfo:nil
                                                    repeats:TRUE];
    [self release];
}

- (void) windowWillClose:(NSNotification*)notification {
	CVDisplayLinkStop(displayLink);
}

- (void) initGL {
	[[self openGLContext] makeCurrentContext];
	
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	
    NSRect viewRectPoints = [self bounds];
	m_renderer = [[OpenGLRenderer alloc] initWithWidth:viewRectPoints.size.width height:viewRectPoints.size.height];
}

- (void) reshape {
	[super reshape];
	CGLLockContext([[self openGLContext] CGLContextObj]);

	// Get the view size in Points
	NSRect viewRectPoints = [self bounds];
    
	// Set the new dimensions in our renderer
	[m_renderer resizeWithWidth:viewRectPoints.size.width
                      AndHeight:viewRectPoints.size.height];
	
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)renewGState {
	[[self window] disableScreenUpdatesUntilFlush];

	[super renewGState];
}

- (void) drawRect: (NSRect) theRect {
	[self drawView];
}

-(void)updatePhysics{
    [m_renderer updatePhysics];
}

- (void) drawView {
    [[self openGLContext] makeCurrentContext];
    
    CGLLockContext([[self openGLContext] CGLContextObj]);
    [m_renderer render];
    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void) keyUp:(NSEvent *)theEvent{
    [m_renderer keyButtonUp:[theEvent charactersIgnoringModifiers]];
}

- (void) keyDown:(NSEvent *)event{
    [m_renderer keyButtonDown:[event charactersIgnoringModifiers]];
}

-(void)mouseMoved:(NSEvent *)theEvent{
    float deltaX = theEvent.deltaX;
    float deltaY = theEvent.deltaY;
    
    [m_renderer mouseMoved:deltaX deltaY:deltaY];
}

- (void) dealloc {
	CVDisplayLinkStop(displayLink);
	CVDisplayLinkRelease(displayLink);
    if (_physicsTimer) {
        [self retain];
        [_physicsTimer invalidate];
        _physicsTimer = nil;
    }
	[m_renderer release];
	
	[super dealloc];
}
@end
