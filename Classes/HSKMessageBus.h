//
//  HSKMessageBus.h
//  Handshake
//
//  Created by Ian Baird on 11/15/08.
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

#import <UIKit/UIKit.h>

#import "RPSNetwork.h"
#import "HSKBypassClient.h"
#import "HSKNetworkIntelligence.h"

@class HSKMessageBus;
@class HSKBypassServer;
@class HSKMessage;

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

/* - (void)messageBusWillDisconnect:(HSKMessageBus *)sender; - unused */
- (void)messageBusDidDisconnect:(HSKMessageBus *)sender;

- (void)messageBusWillReactivate:(HSKMessageBus *)sender;
/* - (void)messageBusDidReactivate:(HSKMessageBus *)sender; - unused */

- (NSData *)messageBusDataForAvatar:(HSKMessageBus *)sender;
- (NSString *)messageBusHandleForUser:(HSKMessageBus *)sender;

// The delegate should attempt to process this message. 
//
// This method is called when the run loop is idle
//
// If the delegate does not process the message, it will return NO.
// If the delegate processes the message, it will return YES.
- (BOOL)messageBus:(HSKMessageBus *)sender processMessage:(HSKMessage *)message queueLength:(NSUInteger)queueLength;


@optional
- (void)messageBus:(HSKMessageBus *)sender sendMessage:(HSKMessage *)message progress:(CGFloat)progressPercent;
- (void)messageBus:(HSKMessageBus *)sender receiveMessage:(HSKMessage *)message progress:(CGFloat)progressPercent;

@end

@interface HSKMessageBus : NSObject <RPSNetworkDelegate, HSKBypassClientDelegate, HSKNetworkIntelligenceDelegate>
{
    HSKBypassServer *dataServer;
    NSNumber *receivePort;
    
    NSString *mappedQuadAddress;
    NSNumber *mappedPort;
    
    NSMutableDictionary* objectsToSend;	    
	NSMutableArray *receivedMessages;
    
    id runLoopObserver;
    
    id <HSKMessageBusDelegate> delegate;
}

@property(nonatomic, assign) id <HSKMessageBusDelegate> delegate;
@property(nonatomic, retain) NSMutableArray *receivedMessages;
@property(nonatomic, retain, readonly) NSArray *receiveAddrs;

+ (HSKMessageBus *)sharedInstance;

- (BOOL)start;
- (void)stop;

- (NSUInteger)sendMessage:(HSKMessage *)message toPeer:(RPSNetworkPeer *)peer compress:(BOOL)shouldCompress;

- (void)removeAllMessages;

- (NSUInteger)messageQueueLength;

@end
