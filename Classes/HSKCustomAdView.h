//
//  HSKCustomAdView.h
//  Handshake
//
//  Created by Ian Baird on 10/17/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface HSKCustomAdView : UIView 
{
    CALayer *imageLayer;
    
    NSDictionary *adInfo;
    
    NSURL *adURL;
	NSString *adString; //image name we wi 
}

@property(nonatomic, retain) CALayer *imageLayer;

- (void)setAdInfo:(NSDictionary *)aDictionary animated:(BOOL)flag;

@end
