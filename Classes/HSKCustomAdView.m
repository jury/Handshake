//
//  HSKCustomAdView.m
//  Handshake
//
//  Created by Ian Baird on 10/17/08.
//  Copyright (c) 2009, Skorpiostech, Inc.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//      * Neither the name of the Skorpiostech, Inc. nor the
//        names of its contributors may be used to endorse or promote products
//        derived from this software without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY SKORPIOSTECH, INC. ''AS IS'' AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL SKORPIOSTECH, INC. BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.//

#import "HSKCustomAdView.h"
#import "Beacon.h"
#import "HSKBeacons.h"

@interface HSKCustomAdView ()

@property(nonatomic, retain) NSDictionary *adInfo;
@property(nonatomic, retain) NSURL *adURL;
@property(nonatomic, retain) NSString *adString;

- (void)setupLayer;

@end

@implementation HSKCustomAdView

@synthesize imageLayer, adInfo, adURL, adString;

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
		self.adString = [adInfo objectForKey:@"image"];
    }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch *touch = [touches anyObject];
    
    if ( ([touch tapCount] > 0) && ([touch phase] == UITouchPhaseEnded) && adURL )
    {
		//log the ad we touched, we are doing it by image name, since it will be unique and using a custom string is overkill
		[[Beacon shared] startSubBeaconWithName:[NSString stringWithFormat:kHSKBeaconAdTouchFormat,self.adString] timeSession:NO];
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
	self.adString = [adInfo objectForKey:@"image"];
    
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
    self.adURL = nil;
	self.adString = nil;
    
    [super dealloc];
}


@end
