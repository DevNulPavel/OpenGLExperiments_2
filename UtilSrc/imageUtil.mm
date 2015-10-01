#include "imageUtil.h"
#import <Cocoa/Cocoa.h>

demoImage* imgLoadImage(const char* filepathname, int flipVertical)
{
	NSString *filepathString = [[NSString alloc] initWithUTF8String:filepathname];
	
#if ESSENTIAL_GL_PRACTICES_IOS
	UIImage* imageClass = [[UIImage alloc] initWithContentsOfFile:filepathString];
#else   
    NSImage *nsimage = [[NSImage alloc] initWithContentsOfFile: filepathString];
	
	NSBitmapImageRep *imageClass = [[NSBitmapImageRep alloc] initWithData:[nsimage TIFFRepresentation]];
	[nsimage release];
#endif
	
	CGImageRef cgImage = imageClass.CGImage;
	if (!cgImage)
	{ 
		[filepathString release];
		[imageClass release];
		return NULL;
	}
	
	demoImage* image = (demoImage*)malloc(sizeof(demoImage));
	image->width = CGImageGetWidth(cgImage);
	image->height = CGImageGetHeight(cgImage);
	image->rowByteSize = image->width * 4;
	image->data = (GLubyte*)malloc(image->height * image->rowByteSize);
	image->format = GL_RGBA;
	image->type = GL_UNSIGNED_BYTE;
	
	CGContextRef context = CGBitmapContextCreate(image->data, image->width, image->height, 8, image->rowByteSize, CGImageGetColorSpace(cgImage), kCGImageAlphaNoneSkipLast);
	CGContextSetBlendMode(context, kCGBlendModeCopy);
	if(flipVertical)
	{
		CGContextTranslateCTM(context, 0.0, image->height);
		CGContextScaleCTM(context, 1.0, -1.0);
	}
	CGContextDrawImage(context, CGRectMake(0.0, 0.0, image->width, image->height), cgImage);
	CGContextRelease(context);
	
	if(NULL == image->data)
	{
		[filepathString release];
		[imageClass release];
		
		imgDestroyImage(image);
		return NULL;
	}
	
	[filepathString release];
	[imageClass release];	
	
	return image;
}

void imgDestroyImage(demoImage* image)
{
	free(image->data);
	free(image);
}