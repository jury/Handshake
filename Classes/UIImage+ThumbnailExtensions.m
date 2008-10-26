//
//  UIImage+ThumbnailExtensions.m
//  kcal
//
//  Created by Ian Baird on 3/28/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "UIImage+ThumbnailExtensions.h"


static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

@implementation UIImage (ThumbnailExtensions)

- (UIImage *)thumbnail:(CGSize)thumbSize
{
    CGRect destRect = CGRectMake(0.0, 0.0, thumbSize.width, thumbSize.height);
    
    if (self.size.width > self.size.height)
    {
        // Scale height down
        destRect.size.height = ceilf(self.size.height * (thumbSize.width / self.size.width));
        
        // Recenter
        destRect.origin.y = (thumbSize.height - destRect.size.height) / 2.0;
    }
    else if (self.size.width < self.size.height)
    {
        // Scale width down
        destRect.size.width = ceilf(self.size.width * (thumbSize.height / self.size.height));
        
        // Recenter
        destRect.origin.x = (thumbSize.width - destRect.size.width) / 2.0;
    }
    
    CGImageRef srcImage = self.CGImage;
    CGColorSpaceRef genericColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef thumbBitmapCtxt = CGBitmapContextCreate(NULL, thumbSize.width, thumbSize.height, 8, (4 * thumbSize.width), genericColorSpace, kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(genericColorSpace);
    CGContextSetInterpolationQuality(thumbBitmapCtxt, kCGInterpolationHigh);
    CGContextDrawImage(thumbBitmapCtxt, destRect, srcImage);
    CGImageRef tmpThumbImage = CGBitmapContextCreateImage(thumbBitmapCtxt);
    CGContextRelease(thumbBitmapCtxt);
    
    UIImage *result = [UIImage imageWithCGImage:tmpThumbImage];
    
    CGImageRelease(tmpThumbImage);
    
    return result;
}

- (UIImage *)roundCorners:(CGSize)cornerSize;
{
    int w = self.size.width;
    int h = self.size.height;
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
	
    CGContextBeginPath(context);
    CGRect rect = CGRectMake(0, 0, w, h);
    addRoundedRectToPath(context, rect, cornerSize.width, cornerSize.height);
    CGContextClosePath(context);
    CGContextClip(context);
	
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), self.CGImage);
	
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
	
    return [UIImage imageWithCGImage:imageMasked];
}

@end
