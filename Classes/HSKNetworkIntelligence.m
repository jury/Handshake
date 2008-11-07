//
//  HSKNetworkIntelligence.m
//  Handshake
//
//  Created by Ian Baird on 11/6/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKNetworkIntelligence.h"


@interface HSKNetworkIntelligence ()

@property(nonatomic, retain) NSTimer *statusPollTimer;
@property(nonatomic, retain) NSArray *lastLocalAddrs;

@end

@implementation HSKNetworkIntelligence

@synthesize statusPollTimer, lastLocalAddrs, delegate;

#pragma mark -
#pragma mark Network Helpers

+ (NSArray*)localAddrs
{
    NSMutableArray *addrs = [NSMutableArray array];
    
    struct ifaddrs *ll;
    struct ifaddrs *llOrigin;
    getifaddrs(&ll);
    
    llOrigin = ll;
    
    while (ll)
    {
        struct sockaddr *sa = ll->ifa_addr;
        if (sa->sa_family == AF_INET)
        {
            struct sockaddr_in *sin = (struct sockaddr_in*)sa;
            char *dottedQuadBuf = inet_ntoa(sin->sin_addr);
            
            if ( (ll->ifa_flags & (IFF_UP | IFF_RUNNING)) && !(ll->ifa_flags & IFF_LOOPBACK) )
            {
                NSLog(@"Iface: %s Found IP: %s", ll->ifa_name, dottedQuadBuf);
                
                [addrs addObject:[[[NSString alloc] initWithBytes:dottedQuadBuf length:strlen(dottedQuadBuf) encoding:NSUTF8StringEncoding] autorelease]];
            }
        }
        
        ll = ll->ifa_next;
    }
    
    freeifaddrs(ll);
    
    return [[addrs copy] autorelease];
}

#pragma mark -
#pragma mark Singleton method

static HSKNetworkIntelligence *_instance = nil;

+ (id)sharedInstance
{
    if (!_instance)
    {
        _instance = [[HSKNetworkIntelligence alloc] init];
    }
    
    return _instance;
}

#pragma mark -
#pragma mark ctor/dtor

- (id)init
{
    if (self = [super init])
    {
        self.lastLocalAddrs = [NSArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [self stopMonitoring];
    
    self.lastLocalAddrs = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Notifcation methods

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    if (_instance)
    {
        [_instance release];
        _instance = nil;
    }
}

#pragma mark -
#pragma mark Public API

- (void)startMonitoring
{
    self.statusPollTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                            target:self 
                                                          selector:@selector(monitoringTimer:) 
                                                          userInfo:nil 
                                                           repeats:YES];
    
}

- (void)stopMonitoring
{
    [self.statusPollTimer invalidate];
    self.statusPollTimer = nil;
}

#pragma mark -
#pragma mark Timer methods

- (void)monitoringTimer:(NSTimer *)aTimer
{
    // TODO: check list of interfaces against new list and IPs - if changed, remap ports and notify delegate.
    NSSet *oldLocalAddrSet = [NSSet setWithArray:self.lastLocalAddrs];
    
    self.lastLocalAddrs = [HSKNetworkIntelligence localAddrs];
    
    NSSet *newLocalAddrSet = [NSSet setWithArray:self.lastLocalAddrs];
    
    if (![oldLocalAddrSet isEqualToSet:newLocalAddrSet] && (niState != kHSKNetworkIntelligenceStateDiscover))
    {
        niState = kHSKNetworkIntelligenceStateDiscover;
        
        struct UPNPDev *upnpDevs = NULL;
        
        upnpDevs = upnpDiscover(2000, NULL, NULL, 0);
        if (upnpDevs == NULL)
        {
            NSLog(@"upnp discover failed!");
        }
        else 
        {
            char lanaddr[16];
            struct UPNPUrls urls;
            struct IGDdatas data;
            
            if (UPNP_GetValidIGD(upnpDevs, &urls, &data, lanaddr, sizeof(lanaddr)))
            {
                NSLog(@"Found IGD: %s", urls.controlURL);
                NSLog(@"Local address: %s", lanaddr);
            }
            else
            {
                NSLog(@"Unable to find a router supporting upnp");
            }
            
            freeUPNPDevlist(upnpDevs);
        }
    }
}


@end
