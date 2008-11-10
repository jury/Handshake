//
//  HSKDataSender.h
//  Handshake
//
//  Created by Ian Baird on 11/9/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HSKDataSender;

@protocol HSKDataSenderProtocol

@required
- (void)dataSenderComplete:(HSKDataSender *)sender;
- (void)dataSenderFail:(HSKDataSender *)sender;

@optional
- (void)dataSender:(HSKDataSender *) progress:(CGFloat)progressPercentage;

@end

@interface HSKDataSender : NSObject 
{
    NSData *dataToSend;
    
    NSString *hostAddress;
    NSNumber *port;
    
    NSString *cookie;
    NSString *type;
    
    NSStream *inStream;
    NSStream *outStream;
    
    id <HSKDataSenderDelegate> delegate;
}

@property(nonatomic, assign) id <HSKDataSenderDelegate> delegate;

- (id)initWithDataToSend:(NSData *)aDataToSend ofType:(NSString *)aType withCookie:(NSString *)aCookie toAddress:(NSString *)aHostAddress port:(NSNumber *)aPort;

- (void)start;
- (void)cancel;

@end
