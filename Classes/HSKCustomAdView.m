//
//  HSKCustomAdView.m
//  Handshake
//
//  Created by Ian Baird on 10/17/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKCustomAdView.h"

@interface HSKCustomAdView ()

@property(nonatomic, retain) NSDictionary *adInfo;
@property(nonatomic, retain) NSURL *adURL;

- (void)setupLayer;

@end

@implementation HSKCustomAdView

@synthesize imageLayer, adInfo, adURL;

- (id)initWithCoder:(NSCoder *)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {        
        self.backgroundColor = [UIColor clearColor];
        [self setupLayer];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame]) 
    {        
        self.backgroundColor = [UIColor clearColor];
        [self setupLayer];
    }
    
    return self;
}

- (void)setupLayer
{
    self.opaque = NO;
    self.imageLayer = [CALayer layer];
    imageLayer.frame = self.layer.bounds;
    imageLayer.opaque = NO;
    
    [self.layer addSublayer:imageLayer];
}

- (void)setAdInfo:(NSDictionary *)aDictionary animated:(BOOL)flag;
{
    self.adInfo = aDictionary;
    
    if (flag)
    {
        float angle = M_PI / 2.0;
        
        CABasicAnimation *flipDownAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
        flipDownAnimation.duration = 0.25;
        flipDownAnimation.toValue = [NSNumber numberWithFloat:angle];
        flipDownAnimation.delegate = self;
        
        // These two settings are key! They cause the presentation to be preserved at the end of the animation.
        flipDownAnimation.fillMode = kCAFillModeForwards;
        flipDownAnimation.removedOnCompletion = NO;
        
        [imageLayer addAnimation:flipDownAnimation forKey:@"transform.rotation.x"];
    }
    else
    {
        imageLayer.contents = (id)[[UIImage imageNamed:[adInfo objectForKey:@"image"]] CGImage];
        
        self.adURL = [NSURL URLWithString:[adInfo objectForKey:@"url"]];
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = [touches anyObject];
    
    if ( ([touch tapCount] > 0) && ([touch phase] == UITouchPhaseEnded) && adURL )
    {
        [[UIApplication sharedApplication] openURL:adURL];
    }
}

#pragma mark -
#pragma mark CAAnimations delegate methods


- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    [self performSelectorOnMainThread:@selector(flipUp) withObject:nil waitUntilDone:NO];
}

- (void)flipUp
{
    [CATransaction begin];
    [CATransaction setValue:[NSNumber numberWithBool:YES] forKey:kCATransactionDisableActions];
    imageLayer.contents = (id)[[UIImage imageNamed:[adInfo objectForKey:@"image"]] CGImage];
    [CATransaction commit];
    
    self.adURL = [NSURL URLWithString:[adInfo objectForKey:@"url"]];
    
    [CATransaction begin];
    CABasicAnimation *flipDownAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
    flipDownAnimation.duration = 0.25;
    flipDownAnimation.fromValue = [NSNumber numberWithFloat:M_PI / 2.0];
    flipDownAnimation.toValue = [NSNumber numberWithFloat:0.0];
    
    // These two settings are key! They cause the presentation to be preserved at the end of the animation.
    flipDownAnimation.fillMode = kCAFillModeForwards;
    flipDownAnimation.removedOnCompletion = NO;
    
    [self.imageLayer addAnimation:flipDownAnimation forKey:@"transform.rotation.x"];
    [CATransaction commit];
}

- (void)dealloc 
{
    self.imageLayer = nil;
    self.adInfo = nil;
    self.adURL;
    
    [super dealloc];
}


@end
