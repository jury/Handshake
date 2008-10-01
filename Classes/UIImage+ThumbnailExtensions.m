//
//  UIImage+ThumbnailExtensions.m
//  kcal
//
//  Created by Ian Baird on 3/28/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "UIImage+ThumbnailExtensions.h"


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

@end
