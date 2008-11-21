//
//  HSKMessageBus.m
//  Handshake
//
//  Created by Ian Baird on 11/15/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKMessageBus.h"

#import "Beacon.h"
#import "HSKBeacons.h"
#import "RPSNetwork.h"
#import "HSKMessage.h"
#import "HSKMessageDefines.h"
#import "HSKBypassServer.h"

@interface HSKMessageBus ()

@property(nonatomic, retain) NSMutableDictionary *objectsToSend;

@property(nonatomic, retain) HSKBypassServer *dataServer;



@property(nonatomic, retain) NSNumber *receivePort;
@property(nonatomic, retain) NSString *mappedQuadAddress;
@property(nonatomic, retain) NSNumber *mappedPort;

@property(nonatomic, retain) id runLoopObserver;

- (void)loadMessagesFromQueue;
- (BOOL)startBypassServer;

- (void)receivedReadyToReceive:(HSKMessage *)message fromPeer:(RPSNetworkPeer *)peer;

- (void)doPollMessageQueue;

@end

@implementation HSKMessageBus

@synthesize dataServer, receivePort, mappedQuadAddress, mappedPort, runLoopObserver, delegate, receivedMessages, objectsToSend;
@dynamic receiveAddrs;

#pragma mark -
#pragma mark ctor/dtor

+ (HSKMessageBus *)sharedInstance
{
    static HSKMessageBus *_instance = nil;
    
    if (!_instance)
    {
        _instance = [[HSKMessageBus alloc] init];
    }
    
    return _instance;
}

- (id)init
{
    if (self = [super init])
    {
        self.receivedMessages = [NSMutableArray array];
        self.objectsToSend = [NSMutableDictionary dictionary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
        
        [self loadMessagesFromQueue];
    }
    
    return self;
}

- (void)dealloc
{
    self.receivedMessages = nil;
    self.receivePort = nil;
    self.mappedQuadAddress = nil;
    self.mappedPort = nil;
    self.objectsToSend = nil;
    
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
    
    [delegate messageBusDidDisconnect:self];
}

- (void)connectionSucceeded:(RPSNetwork *)sender infoDictionary:(NSDictionary *)infoDictionary
{
	[[Beacon shared] startSubBeaconWithName:kHSKBeaconServerConnectionSucceededEvent timeSession:NO];
    
    [delegate messageBusDidConnect:self];
}

- (void)messageReceived:(RPSNetwork *)sender fromPeer:(RPSNetworkPeer *)peer message:(id)message
{	    
	//not a ping lets handle it
    if([message isEqual:@"PING"])
	{
        return;
    }
    
    HSKMessage *newMessage = [HSKMessage messageWithDictionaryRepresentation:message];
    newMessage.fromPeer = peer;
    
    NSLog(@"received message: %@", newMessage);
    
    if ([newMessage.type isEqualToString:kHSKMessageTypeReadyToReceive])
    {
        [self receivedReadyToReceive:newMessage fromPeer:peer];
    }
    else if (![delegate messageBus:self processMessage:newMessage queueLength:([receivedMessages count] + 1)])
    {
        NSLog(@"enqueuing message: %@", newMessage);
        
        [receivedMessages addObject:newMessage];
        
        [self doPollMessageQueue];
    }
}

- (void)connectionWillReactivate:(RPSNetwork *)sender
{
    NSLog(@"Reconnecting to the server due to wake...");
    
    [delegate messageBusWillReactivate:self];
}

- (void)messageSuccess:(RPSNetwork *)sender contextHandle:(NSUInteger)context
{
}

- (void)messageFailed:(RPSNetwork *)sender contextHandle:(NSUInteger)context
{
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
#pragma mark Private API methods

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
            self.receivedMessages =[[data mutableCopy] autorelease];
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
    
    network.handle = [delegate messageBusHandleForUser:self];
    network.avatarData = [delegate messageBusDataForAvatar:self];
    
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
#pragma mark Message handling methods

- (void)receivedReadyToReceive:(HSKMessage *)message fromPeer:(RPSNetworkPeer *)peer
{
    // Reply
    HSKMessage *messageToSend = [self.objectsToSend objectForKey:message.cookie];
    
    if (messageToSend)
    {
        NSLog(@"message to send: %@", messageToSend);
        
        if (!message.isDeclined)
        {
            NSLog(@"sending message");
            [[RPSNetwork sharedNetwork] sendMessage:[messageToSend dictionaryRepresentation] toPeer:peer compress:YES];
        }
        else
        {
            NSLog(@"message was declined");
        }
        
        // We have to lie here, just in case the other side politely declines it
        [delegate messageBus:self didSendMessage:messageToSend];
        
        [self.objectsToSend removeObjectForKey:messageToSend.cookie];
    }
    else
    {
        if (!messageToSend)
        {
            NSLog(@"Unable to find object to send for cookie: %@", message.cookie);
        }
    }
}

#pragma mark -
#pragma mark Public API methods

static void pollMessageQueue(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    HSKMessageBus *messageBus = (HSKMessageBus *)info;
        
    [messageBus doPollMessageQueue];
}

- (void)doPollMessageQueue
{    
    if ([receivedMessages count])
    {
        HSKMessage *message = [[receivedMessages objectAtIndex:0] retain];
        
        // Remove from the queue
        [receivedMessages removeObjectAtIndex:0];
        
        if (![delegate messageBus:self processMessage:message queueLength:[receivedMessages count]])
        {
            // Re-insert the message, the delegate elected not to process it.
            [receivedMessages insertObject:message atIndex:0];
        }
        
        [message release];
    }
}

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
        
        self.runLoopObserver = (id) CFRunLoopObserverCreate(NULL, kCFRunLoopBeforeWaiting | kCFRunLoopAfterWaiting, true, 0, pollMessageQueue, &ctxt);
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

- (NSUInteger)sendMessage:(HSKMessage *)message toPeer:(RPSNetworkPeer *)peer compress:(BOOL)shouldCompress
{
    HSKMessage *messageToSend = nil;
    
    if (![message.type isEqualToString:kHSKMessageTypeReadyToReceive] && ![message.type isEqualToString:kHSKMessageTypeReadyToSend])
    {
        [self.objectsToSend setObject:message forKey:message.cookie];
        
        messageToSend = [HSKMessage message];
        messageToSend.version = kHSKProtocolVersion2_0;
        messageToSend.cookie = message.cookie;
        messageToSend.type = kHSKMessageTypeReadyToSend;
        messageToSend.wrappedType = message.type;
    }
    else
    {
        messageToSend = message;
    }
    
    NSLog(@"sending message: %@", messageToSend);
    
    return [[RPSNetwork sharedNetwork] sendMessage:[messageToSend dictionaryRepresentation] toPeer:peer compress:shouldCompress];
}

- (void)removeAllMessages
{
    [self.receivedMessages removeAllObjects];
}

- (NSUInteger)messageQueueLength
{
    return [receivedMessages count];
}

#pragma mark -
#pragma mark UIAppicationDelegate methods

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:self.receivedMessages];
	[[NSUserDefaults standardUserDefaults] setObject:messageData forKey:@"storedMessages"];
    
    // Write the app version into the defaults
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"defaultsVersion"];
}

#pragma mark -
#pragma mark HSKBypassClientDelegate

- (void)dataClientComplete:(HSKBypassClient *)sender
{
}
- (void)dataClientFail:(HSKBypassClient *)sender
{
}

@end
