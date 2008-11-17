//
//  HSKMessageBus.m
//  Handshake
//
//  Created by Ian Baird on 11/15/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKMessageBus.h"

#import "HSKDataBus.h"

@interface HSKMessageBus ()

@property(nonatomic, retain) HSKBypassServer *dataServer;
@property(nonatomic, retain) NSMutableArray *messageArray;
@property(nonatomic, retain, readonly) NSArray *receiveAddrs;

- (void)loadMessagesFromQueue;
- (void)startBypassServer;

@end

@implementation HSKMessageBus

@synthesize dataServer, receivePort, mappedQuadAddress, mappedPort;
@dynamic receiveAddrs;

#pragma mark -
#pragma mark ctor/dtor

- (id)init
{
    if (self = [super init])
    {
        self.messageArray = [NSMutableArray array];
        self.objectsToSend = [NSMutableDictionary dictionary];
        
        [self loadMessagesFromQueue];
    }
    
    return self;
}

- (void)dealloc
{
    self.messageArray = nil;
    self.receivePort = nil;
    self.mappedQuadAddress = nil;
    self.mappedPort = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark HSKNetworkIntelligenceDelegate protocol methods

- (unsigned short)networkIntelligenceShouldMapPort:(HSKNetworkIntelligence *)sender
{
    // Return the port we want mapped
    return [receivePort unsignedShortValue];
}

- (void)networkIntelligenceMappedPort:(HSKNetworkIntelligence *)sender externalPort:(NSNumber *)port externalAddress:(NSString *)dottedQuad
{
    NSLog(@"DELEGATE: external port: %@ at dottedQuad: %@ was mapped!", port, dottedQuad);
    
    self.mappedQuadAddress = dottedQuad;
    self.mappedPort = port;
}

#pragma mark -
#pragma mark RPSNetworkDelegate methods

- (void)connectionFailed:(RPSNetwork *)sender
{
	[[Beacon shared] startSubBeaconWithName:kHSKBeaconServerConnectionFailedEvent timeSession:NO];
	[self handleConnectFail];
    
    [self hideShareButton];
}

- (void)connectionSucceeded:(RPSNetwork *)sender infoDictionary:(NSDictionary *)infoDictionary
{
	[[Beacon shared] startSubBeaconWithName:kHSKBeaconServerConnectionSucceededEvent timeSession:NO];
    
    // Kill the timer if it's out there
    NSLog(@"TIMER: Killing overlay timer");
    [self.overlayTimer invalidate];
    self.overlayTimer = nil;
    
    if (self.isShowingOverlayView)
    {
        [self hideOverlayView];
    }
    
    // Disable or enable the "Share" button based on a server flag.
    NSNumber *smsFlag = [infoDictionary objectForKey:@"enable_sms"];
    if (smsFlag && [smsFlag boolValue])
    {
        [self showShareButton];
    }
    else
    {
        [self hideShareButton];
    }
}

- (void)messageReceived:(RPSNetwork *)sender fromPeer:(RPSNetworkPeer *)peer message:(id)message
{	    
	//not a ping lets handle it
    if([message isEqual:@"PING"])
	{
        return;
    }
    
    if (userBusy)
    {
        if([[NSDate date] timeIntervalSinceDate: self.lastSoundPlayed] > 0.5)
        {
            [receive play];
            if (![[[UIDevice currentDevice] model] isEqualToString: @"iPhone"])
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
            
            self.lastSoundPlayed = [NSDate date];
        }
        
        [self.messageArray addObject:[NSDictionary dictionaryWithObjectsAndKeys: peer, @"peer", message, @"message", nil]];
        
        return;
    }
    
    if(!userBusy)
    {
        [self playReceived];
        
        //client sees	
        self.lastMessage = message;
        self.lastPeer = peer;
        lastPeerHandle = peer.handle;
        
        userBusy = TRUE;
        //App will not let user proceed if if is about to post a message but if you hit it spot
        //on it will highlight the row and lock it
        [mainTable deselectRowAtIndexPath: [mainTable indexPathForSelectedRow] animated: YES];
        
        if([[message objectForKey: kHSKMessageTypeKey] isEqualToString:kHSKMessageTypeVcard])
        {
            [self receivedVcardMessage:message fromPeer:peer];
        }
        
        //vcard was returned
        else if([[message objectForKey: kHSKMessageTypeKey] isEqualToString:kHSKMessageTypeVcardBounced])
        {
            [self receivedVcardBounceMessage:message fromPeer:peer];
        }
        
        else if([[message objectForKey: kHSKMessageTypeKey] isEqualToString:kHSKMessageTypeImage])
        {
            [self receivedImageMessage:message fromPeer:peer];
        }
        
        else if([[message objectForKey: kHSKMessageTypeKey] isEqualToString:kHSKMessageTypeReadyToSend])
        {
            [self receivedReadyToSend:message fromPeer:peer];
            
        }
        
        else if ([[message objectForKey: kHSKMessageTypeKey] isEqualToString:kHSKMessageTypeReadyToReceive])
        {
            [self receivedReadyToReceive:message fromPeer:peer];
        }
    }
    
}

- (void)connectionWillReactivate:(RPSNetwork *)sender
{
    NSLog(@"Reconnecting to the server due to wake...");
    [self hideShareButton];
    [self showOverlayView:NSLocalizedString(@"Connecting to the server…", @"Connecting to the server overlay view message") reconnect:YES];
    [[Beacon shared] startSubBeaconWithName:kHSKBeaconServerBeginReconnectionEvent timeSession:NO];
}


#pragma mark -
#pragma mark Accessor methods

- (NSArray *)receiveAddrs
{
    NSMutableArray *tmpreceiveAddrs = [NSMutableArray array];
    
    NSArray *baseQuads = [HSKNetworkIntelligence localAddrs];
    
    for (NSString *baseQuad in baseQuads)
    {
        NSDictionary *tmpEntry = [NSDictionary dictionaryWithObjectsAndKeys:baseQuad,@"dottedquad",receivePort,@"port",nil];
        [tmpreceiveAddrs addObject:tmpEntry];
    }
    
    if ((self.mappedQuadAddress != nil) && (self.mappedPort != nil))
    {
        NSDictionary *tmpEntry = [NSDictionary dictionaryWithObjectsAndKeys:self.mappedQuadAddress,@"dottedquad",self.mappedPort,@"port",nil];
        [tmpreceiveAddrs addObject:tmpEntry];
    }
    
    return tmpreceiveAddrs;
}

#pragma mark -
#pragma mark private api

- (void)loadMessagesFromQueue
{
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    
    if ([appVersion isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"defaultsVersion"]])
    {
        NSLog(@"matching defaults version");
        // Only load defaults if app versions are equal. Otherwise, it's just too dangerous
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"storedMessages"] != nil)
        {
            NSArray *data = [NSKeyedUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] objectForKey:@"storedMessages"]];
            self.messageArray =[[data mutableCopy] autorelease];
        }
        
        
    }
    
    else
    {
        NSLog(@"non-matching defaults version");
    }
}

- (BOOL)startBypassServer
{
    // Start up the data server
    // TODO: disable by preference
    BOOL success;
    
    self.dataServer = [[[HSKBypassServer alloc] init] autorelease];
    [dataServer createDefaultSocketListener];
    dataServer.socketListener.name = @"Data";
    
    NSError *theError = nil;
    [dataServer.socketListener start:&theError];
    
    if (theError)
    {
        self.dataServer = nil;
        NSLog(@"Unable to start the data server, error was: %@", [theError localizedDescription]);
        self.receivePort = [NSNumber numberWithUnsignedShort:0];
        
        success = NO;
    }
    else
    {
        NSLog(@"Data server started on port: %d", dataServer.socketListener.port);
        self.receivePort = [NSNumber numberWithUnsignedShort:dataServer.socketListener.port];
        
        success = YES;
    }
    
    return success;
}    

- (BOOL)startHalley
{
    BOOL success = YES;
	RPSNetwork *network = [RPSNetwork sharedNetwork];
    network.delegate = self;
    
    NSString *handle = [delegate messageBusHandleForUser:self];
    NSData *avatarData = [delegate messageBusDataForAvatar:self];
    
    if ([[RPSNetwork sharedNetwork] isConnected])
    {
        [[RPSNetwork sharedNetwork] disconnect];
    }
    
    if (![[RPSNetwork sharedNetwork] connect])
    {
        success = false;
    }
    
    return success;
}

#pragma mark -
#pragma mark Public API methods

- (BOOL)start
{
    BOOL success = NO;
    
    if ([self startHalley] && [self startBypassServer])
    {
        [[HSKNetworkIntelligence sharedInstance] setDelegate:self];
        [[HSKNetworkIntelligence sharedInstance] performSelector:@selector(startMonitoring) withObject:nil afterDelay:0.0];
        
        CFRunLoopObserverContext ctxt;
        memset(&ctxt, 0, sizeof(ctxt));
        ctxt.info = (void *)self;
        
        self.runLoopObserver = (id) CFRunLoopObserverCreate(NULL, kCFRunLoopBeforeWaiting, true, 0, pollMessageQueue, &ctxt);
        CFRunLoopAddObserver(CFRunLoopGetCurrent(), (CFRunLoopObserverRef)self.runLoopObserver, kCFRunLoopCommonModes);
        
        success = YES;
    }
    
    return success;
}

- (void)stop
{
    if (dataServer)
    {
        [[HSKNetworkIntelligence sharedInstance] stopMonitoring];
        
        [dataServer.socketListener stop];
        self.dataServer = nil;
    }
    
    if (self.runLoopObserver)
    {
        CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), (CFRunLoopObserverRef)self.runLoopObserver, kCFRunLoopCommonModes);
        self.runLoopObserver = nil;
    }
}

@end
