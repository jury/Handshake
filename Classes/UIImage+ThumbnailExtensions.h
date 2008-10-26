//
//  UIImage+ThumbnailExtensions.h
//  kcal
//
//  Created by Ian Baird on 3/28/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIImage (ThumbnailExtensions) 

- (UIImage *)thumbnail:(CGSize)thumbSize;
- (UIImage *)roundCorners:(CGSize)cornerSize;

@end
