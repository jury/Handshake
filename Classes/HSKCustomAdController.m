//
//  HSKCustomAdController.m
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

#import "HSKCustomAdController.h"
#import "HSKCustomAdView.h"

@interface HSKCustomAdController ()

@property(nonatomic, retain) NSTimer *adTimer;
@property(nonatomic, retain) NSArray *adGroups;
@property(nonatomic, retain) NSMutableArray *adPlaylist;

- (void)setupController;
- (void)serveNextAd:(NSTimer *)aTimer;

@end

@implementation HSKCustomAdController

@synthesize adTimer, adGroups, adPlaylist, verticalFlipImageView;

- (id)init
{
    if (self = [super init])
    {
        [self setupController];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aCoder
{
    if (self = [super init])
    {
        [self setupController];
    }
    
    return self;
}

- (void)setupController
{
    srandomdev();
    
    NSString *errorString = nil;
    NSData *adGroupsData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AdGroups" ofType:@"plist"]];
    self.adGroups = [NSPropertyListSerialization propertyListFromData:adGroupsData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
}

- (void)buildPlaylist
{
    NSUInteger nonSpecialGroups = [adGroups count] - 1;
    
    NSUInteger maxAdGroupCount = 0;
    for (NSArray *adGroup in adGroups)
    {
        if ([adGroup count] > maxAdGroupCount)
        {
            maxAdGroupCount = [adGroup count];
        }
    }
    
    
    NSUInteger i;
    
    NSData *adGroupsData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AdGroups" ofType:@"plist"]];
    NSString *errorString = nil;
    NSMutableArray *tmpAdGroups = [NSPropertyListSerialization propertyListFromData:adGroupsData mutabilityOption:NSPropertyListMutableContainers format:NULL errorDescription:&errorString];
    
    self.adPlaylist = [NSMutableArray array];

    // Add the regular ads
    long adGroupInd = random() % nonSpecialGroups;
    for (i = 0; i < (maxAdGroupCount * nonSpecialGroups);  ++i)
    {
        if (adGroupInd >= nonSpecialGroups)
        {
            adGroupInd = 0;
        }
        
        NSMutableArray *tmpAdGroup = [tmpAdGroups objectAtIndex:adGroupInd];
        if (![tmpAdGroup count])
        {
            tmpAdGroup = [[[adGroups objectAtIndex:adGroupInd] mutableCopy] autorelease];
            [tmpAdGroups replaceObjectAtIndex:adGroupInd withObject:tmpAdGroup];
        }
        
        NSUInteger tmpAdInd = random() % [tmpAdGroup count];
        [adPlaylist addObject:[tmpAdGroup objectAtIndex:tmpAdInd]];
        
        [tmpAdGroup removeObjectAtIndex:tmpAdInd];
        
        adGroupInd++;
    }
    
    // Add the "special ads"
    for (NSDictionary *adInfo in [adGroups lastObject])
    {
        NSUInteger tmpAdInd = random() % [adPlaylist count];
        [adPlaylist insertObject:adInfo atIndex:tmpAdInd];
    }
    
    //NSLog(@"Ad Playlist: %@", adPlaylist);
}

- (void)startAdServing
{
    [self buildPlaylist];
    
    [self serveNextAd:nil];
    
    self.adTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(serveNextAd:) userInfo:nil repeats:YES];
}

- (void)stopAdServing
{
    [self.adTimer invalidate];
    self.adTimer = nil;
    self.adPlaylist = nil;
}

- (void)serveNextAd:(NSTimer *)aTimer
{
    if (![adPlaylist count])
    {
        [self buildPlaylist];
    }
    
    NSDictionary *adInfo = [adPlaylist lastObject];
    
    if (adInfo)
    {
        [verticalFlipImageView setAdInfo:adInfo animated:(aTimer != nil)];
        [adPlaylist removeObjectAtIndex:[adPlaylist count] - 1];
    }
}

- (void)dealloc
{
    [self stopAdServing];
    
    self.adGroups = nil;
    self.adPlaylist = nil;
    self.verticalFlipImageView = nil;
    
    [super dealloc];
}

@end
