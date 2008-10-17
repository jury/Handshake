//
//  HSKCustomAdController.m
//  Handshake
//
//  Created by Ian Baird on 10/17/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKCustomAdController.h"
#import "HSKCustomAdView.h"

@interface HSKCustomAdController ()

@property(nonatomic, retain) NSTimer *adTimer;
@property(nonatomic, retain) NSArray *adGroups;
@property(nonatomic, retain) NSMutableArray *adPlaylist;

- (void)serveNextAd:(NSTimer *)aTimer;

@end

@implementation HSKCustomAdController

@synthesize adTimer, adGroups, adPlaylist;

- (void)awakeFromNib
{
    srandomdev();
     
    NSString *errorString = nil;
    NSData *adGroupsData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AdGroups" ofType:@"plist"]];
    self.adGroups = [NSPropertyListSerialization propertyListFromData:adGroupsData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
    
    [self startAdServing];
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
    
    NSLog(@"Ad Playlist: %@", adPlaylist);
}

- (void)startAdServing
{
    [self buildPlaylist];
    
    [self serveNextAd:nil];
    
    self.adTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(serveNextAd:) userInfo:nil repeats:YES];
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
    
    [super dealloc];
}

@end
