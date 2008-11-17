//
//  HSKMessageBus.h
//  Handshake
//
//  Created by Ian Baird on 11/15/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RPSNetwork.h"
#import "HSKBypassClient.h"
#import "HSKNetworkIntelligence.h"

@class HSKMessageBus;
@class HSKBypassServer;

@protocol HSKMessageBusDelegate

@required
- (void)messageBus:(HSKMessageBus *)sender willSendMessage:(HSKMessage *)message;
- (void)messageBus:(HSKMessageBus *)sender didSendMessage:(HSKMessage *)message;
- (void)messageBus:(HSKMessageBus *)sender didFailMessageSend:(HSKMessage *)message;

- (void)messageBus:(HSKMessageBus *)sender willReceiveMessage:(HSKMessage *)message;
- (void)messageBus:(HSKMessageBus *)sender didReceiveMessage:(HSKMessage *)message;
- (void)messageBus:(HSKMessageBus *)sender didFailMessageReceive:(HSKMessage *)message;

- (void)messageBusWillConnect:(HSKMessageBus *)sender;
- (void)messageBusDidConnect:(HSKMessageBus *)sender;

- (void)messageBusWillDisconnect:(HSKMessageBus *)sender;
- (void)messageBusDidDisconnect:(HSKMessageBus *)sender;

- (void)messageBusWillReactivate:(HSKMessageBus *)sender;
- (void)messageBusDidReactivate:(HSKMessageBus *)sender;

- (NSData *)messageBusDataForAvatar:(HSKMessageBus *)sender;
- (NSString *)messageBusHandleForUser:(HSKMessageBus *)sender;

// The delegate should attempt to process this message. 
//
// This method is called when the run loop is idle
//
// If the delegate does not process the message, it will return NO.
// If the delegate processes the message, it will return YES.
- (BOOL)messageBus:(HSKMessageBus *) processMessage:(HSKMessage *)message popAllMessages:(BOOL*)popAllFlag;


@optional
- (void)messageBus:(HSKMessageBus *)sender sendMessage:(HSKMessage *)message progress:(CGFloat)progressPercent;
- (void)messageBus:(HSKMessageBus *)sender receiveMessage:(HSKMessage *)message progress:(CGFloat)progressPercent;

@end

@interface HSKMessageBus : NSObject <RPSNetworkDelegate, HSKDataClientDelegate, HSKNetworkIntelligenceDelegate>
{
    HSKDataServer *dataServer;
    NSNumber *receivePort;
    
    NSString *mappedQuadAddress;
    NSNumber *mappedPort;
    
    NSMutableDictionary* objectsToSend;	
    NSString *cookieToSend;
    
	NSMutableArray *messageArray;
    
    CFRunLoopObserverRef runLoopObserver;
}

- (BOOL)start;

@end
