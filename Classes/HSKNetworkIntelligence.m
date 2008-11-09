//
//  HSKNetworkIntelligence.m
//  Handshake
//
//  Created by Ian Baird on 11/6/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKNetworkIntelligence.h"

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

@interface HSKNetworkIntelligence ()

@property(nonatomic, retain) NSTimer *statusPollTimer;
@property(nonatomic, retain) NSArray *lastLocalAddrs;
@property(nonatomic, retain) NSMutableArray *services;

- (void)monitoringTimer:(NSTimer *)aTimer;

- (BOOL)registerUPNP;
- (BOOL)registerNATPMPWithAddress:(struct sockaddr_in *)sin;

@end

@implementation HSKNetworkIntelligence

@synthesize statusPollTimer, lastLocalAddrs, delegate, services;

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
    self.services = nil;
    
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
    enabled = YES;
    [self monitoringTimer:nil];
}

- (void)stopMonitoring
{
    enabled = NO;
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

        [self registerUPNP];
        
        NSNetServiceBrowser *serviceBrowser;
        
        self.services = [NSMutableArray array];
        
        serviceBrowser = [[NSNetServiceBrowser alloc] init];
        [serviceBrowser setDelegate:self];
        [serviceBrowser searchForServicesOfType:@"_airport._tcp" inDomain:@""];
    }
    
    if (enabled)
    {
        self.statusPollTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                target:self 
                                                              selector:@selector(monitoringTimer:) 
                                                              userInfo:nil 
                                                               repeats:NO];
    }
}

- (BOOL)registerUPNP
{
    BOOL success = NO;
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
            
            unsigned short port = [delegate networkIntelligenceShouldMapPort:self];
            char portStr[10];
            snprintf(portStr, sizeof(portStr)-1, "%d", port);
            
            char externalDottedQuadBuf[17];
            int err = UPNP_GetExternalIPAddress(urls.controlURL,
                                                data.servicetype,
                                                externalDottedQuadBuf);
            if (port && !err)
            {
                // Attempt to map it
                err = UPNP_AddPortMapping(urls.controlURL, data.servicetype, portStr, portStr, lanaddr, "Handshake", "TCP");
                if (!err)
                {
                    NSString *externalDottedQuad = [[[NSString alloc] initWithBytes:externalDottedQuadBuf length:strlen(externalDottedQuadBuf) encoding:NSUTF8StringEncoding] autorelease];
                    [delegate networkIntelligenceMappedPort:self 
                                               externalPort:[NSNumber numberWithUnsignedShort:port] 
                                            externalAddress:externalDottedQuad];
                    
                    success = YES;
                }
                else
                {
                    NSLog(@"Unable to map port: %d err: %d", port, err);
                }
            }
            else
            {
                NSLog(@"MAP FAIL - port: %d err: %d", port, err);
            }
        }
        else
        {
            NSLog(@"Unable to find a router supporting upnp");
        }
        
        freeUPNPDevlist(upnpDevs);
    }
    
    return success;
}    

- (BOOL)registerNATPMPWithAddress:(struct sockaddr_in *)sin
{
    BOOL success = NO;
    mappingNATPMP = YES;
    
    natpmp_t natpmp;
    int val = initnatpmp( &natpmp, sin );
    NSLog(@"val: %d", val);
    val = sendpublicaddressrequest( &natpmp );
    if (val >= 0)
    {
        natpmpresp_t response;
        val = NATPMP_TRYAGAIN;
        int ticks = 0;
        int maxticks = 30; // 3 seconds
        while ((val == NATPMP_TRYAGAIN) && (ticks < maxticks))
        {
            val = readnatpmpresponseorretry( &natpmp, &response );
            
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, true);
            
            ++ticks;
        }
        if (val >= 0)
        {
            NSLog(@"found addr: %s", inet_ntoa( response.pnu.publicaddress.addr ));
            
            NSString *externalDottedQuad = [[[NSString alloc] initWithBytes:inet_ntoa( response.pnu.publicaddress.addr ) 
                                                                     length:strlen(inet_ntoa( response.pnu.publicaddress.addr )) 
                                                                   encoding:NSUTF8StringEncoding] autorelease];
            
            unsigned short port = [delegate networkIntelligenceShouldMapPort:self];
            
            // Open the port for an hour 
            // TODO: set a timer to remap if needed
            val = sendnewportmappingrequest( &natpmp, NATPMP_PROTOCOL_TCP, port, port, 60 * 60 );
            if (val >= 0)
            {
                ticks = 0; 
                val = NATPMP_TRYAGAIN;
                while ((val == NATPMP_TRYAGAIN) && (ticks < maxticks))
                {
                    val = readnatpmpresponseorretry( &natpmp, &response );
                    
                    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, true);
                    
                    ++ticks;
                }
                if (val >=0)
                {
                    NSLog(@"port (%d) forwarded", port);
                    
                    [delegate networkIntelligenceMappedPort:self 
                                               externalPort:[NSNumber numberWithUnsignedShort:port] 
                                            externalAddress:externalDottedQuad];
                }
                else
                {
                    NSLog(@"unable to map port: %d", val);
                }
                
            }
            else
            {
                NSLog(@"unable to map port: %d", val);
            }
            
            
        }
        else
        {
            NSLog(@"unable to find a gateway: %d", val);
        }
    }
    else
    {
        NSLog(@"error: %d", val);
    }
    
    closenatpmp(&natpmp);
    
    mappingNATPMP = NO;
    return success;
}

#pragma mark -
#pragma mark NSNetServiceBrowser delegate methods

// Sent when browsing begins
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
{
    searching = YES;
}

// Sent when browsing stops
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
    searching = NO;
    niState = kHSKNetworkIntelligenceStateIdle;
    
    [browser release];
    self.services = nil;
}

// Sent if browsing fails
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
             didNotSearch:(NSDictionary *)errorDict
{
    searching = NO;
}

// Sent when a service appears
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
           didFindService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing
{
    [services addObject:aNetService];
    if(!moreComing)
    {
        NSLog(@"service appeared");
        
        for (NSNetService *service in services)
        {
            NSLog(@"resolving service: %@", service);
            [service retain];
            [service setDelegate:self];
            [service resolveWithTimeout:5.0];
        }
        
        self.services = nil;
    }
}

// Sent when a service disappears
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
         didRemoveService:(NSNetService *)aNetService
               moreComing:(BOOL)moreComing
{
    [services removeObject:aNetService];
    NSLog(@"service disappeared");
}

#pragma mark -
#pragma mark NSNetService delegate methods

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog(@"resolved service: %@\n\n%@", sender, [sender addresses]);
    
    for (NSData *address in [sender addresses])
    {
        struct sockaddr_in *sin = (struct sockaddr_in *)[address bytes];
        if (sin->sin_family == AF_INET)
        {
            [self registerNATPMPWithAddress:sin];
        }
    }
    
    [sender release];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog(@"failed to resolve service: %@", sender);
    
    [sender release];
}

@end
