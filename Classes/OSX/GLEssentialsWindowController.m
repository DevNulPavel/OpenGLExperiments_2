#import "GLEssentialsWindowController.h"
#import "GLEssentialsFullscreenWindow.h"

@interface GLEssentialsWindowController ()
@end


@implementation GLEssentialsWindowController

BOOL wasBackgroundedOutOfFullScreen;

GLEssentialsFullscreenWindow *fullscreenWindow;
NSWindow* standardWindow;

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];

	if (self){
		fullscreenWindow = nil;
    }

	return self;
}

- (void) goFullscreen {
	if(fullscreenWindow){
		return;
	}

	fullscreenWindow = [[GLEssentialsFullscreenWindow alloc] init];
	NSRect viewRect = [fullscreenWindow frame];
	[view setFrameSize: viewRect.size];
	[fullscreenWindow setContentView:view];

	standardWindow = [self window];
	[standardWindow orderOut:self];
	[self setWindow:fullscreenWindow];

	[fullscreenWindow makeKeyAndOrderFront:self];
}

- (void) goWindow {
	if(fullscreenWindow == nil) {
		return;
	}

	NSRect viewRect = [standardWindow frame];
	
	[view setFrame:viewRect];

	[self setWindow:standardWindow];
	[[self window] setContentView:view];
	[[self window] makeKeyAndOrderFront:self];

	[fullscreenWindow release];
	fullscreenWindow = nil;
}

-(void)mouseDragged:(NSEvent *)theEvent{
    [view mouseMoved:theEvent];
    [super mouseDragged:theEvent];
}

-(void)mouseEntered:(NSEvent *)theEvent{
    [super mouseEntered:theEvent];
}

-(void)mouseMoved:(NSEvent *)theEvent{
    [super mouseMoved:theEvent];
}

- (void) keyDown:(NSEvent *)event {
	unichar c = [[event charactersIgnoringModifiers] characterAtIndex:0];

	switch (c) {
		case 27:
			if(fullscreenWindow != nil) {
				[self goWindow];
			}
			return;
		case 'f':
			if(fullscreenWindow == nil){
				[self goFullscreen];
			} else {
				[self goWindow];
			}
			return;
	}

    [view keyDown:event];
}

- (void) keyUp:(NSEvent *)theEvent {
    [view keyUp:theEvent];
}

@end
