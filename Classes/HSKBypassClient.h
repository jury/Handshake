//
//  HSKDataSender.h
//  Handshake
//
//  Created by Ian Baird on 11/9/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CFNetwork/CFNetwork.h>

@class HSKBypassClient;

@protocol HSKBypassClientDelegate

@required
- (void)dataClientComplete:(HSKBypassClient *)sender;
- (void)dataClientFail:(HSKBypassClient *)sender;

@optional
- (void)dataClient:(HSKBypassClient *)sender progress:(CGFloat)progressPercentage;

@end

@interface HSKBypassClient : NSObject 
{
    NSData *dataToSend;
    NSUInteger dataToSendOffset;
    
    NSArray *hostAddrs;
    
    NSInputStream *inStream;
    NSOutputStream *outStream;
    
    NSTimer *livenessTimer;
    
    id <HSKBypassClientDelegate> delegate;
    
    BOOL completed;
}

@property(nonatomic, assign) id <HSKBypassClientDelegate> delegate;
@property(nonatomic, retain) NSData *dataToSend;
@property(nonatomic, retain) NSArray *hostAddrs;

- (BOOL)start;
- (void)cancel;

@end
