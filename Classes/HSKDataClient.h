//
//  HSKDataSender.h
//  Handshake
//
//  Created by Ian Baird on 11/9/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CFNetwork/CFNetwork.h>

@class HSKDataClient;

@protocol HSKDataClientDelegate

@required
- (void)dataClientComplete:(HSKDataClient *)sender;
- (void)dataClientFail:(HSKDataClient *)sender;

@optional
- (void)dataClient:(HSKDataClient *)sender progress:(CGFloat)progressPercentage;

@end

@interface HSKDataClient : NSObject 
{
    NSData *dataToSend;
    NSUInteger dataToSendOffset;
    
    NSArray *hostAddrs;
    
    NSInputStream *inStream;
    NSOutputStream *outStream;
    
    NSTimer *livenessTimer;
    
    id <HSKDataClientDelegate> delegate;
    
    BOOL completed;
}

@property(nonatomic, assign) id <HSKDataClientDelegate> delegate;
@property(nonatomic, retain) NSData *dataToSend;
@property(nonatomic, retain) NSArray *hostAddrs;

- (BOOL)start;
- (void)cancel;

@end
