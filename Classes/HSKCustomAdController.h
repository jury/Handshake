//
//  HSKCustomAdController.h
//  Handshake
//
//  Created by Ian Baird on 10/17/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HSKCustomAdView;

@interface HSKCustomAdController : NSObject 
{
    IBOutlet HSKCustomAdView *verticalFlipImageView;
    
    NSTimer *adTimer;
    NSArray *adGroups;
    
    NSMutableArray *adPlaylist;
}

- (void)startAdServing;
- (void)stopAdServing;

@end
