//
//  SKPInputStreamConnector.h
//  Handshake
//
//  Created by Ian Baird on 11/30/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKPInputStreamConnector;

@protocol SKPInputStreamConnectorDelegate <NSObject>

@optional
- (BOOL)connector:(SKPInputStreamConnector *)sender didParseHTTPResponse:(CFHTTPMessageRef)response;
- (void)connector:(SKPInputStreamConnector *)sender didCompleteUpstreamOpen:(NSInputStream *)upstream;
- (void)connectorDidComplete:(SKPInputStreamConnector*)sender;
- (void)connector:(SKPInputStreamConnector *)sender didFail:(NSError *)error;

@end

@interface SKPInputStreamConnector : NSObject 
{
    NSInputStream *upstreamStream;
    
    NSInputStream *downstreamStream;
    NSOutputStream *internalStream;
    
    NSRunLoop *workerRunLoop;
    NSThread *workerThread;
    
    CFHTTPMessageRef response;
    
    id <SKPInputStreamConnectorDelegate> delegate;
}

@property(nonatomic, retain, readonly) NSInputStream *upstreamStream;
@property(nonatomic, retain, readonly) NSInputStream *downstreamStream;
@property(nonatomic, assign) id <SKPInputStreamConnectorDelegate> delegate;

- (id)initWithUpstream:(NSInputStream *)aStream;
- (NSData *)transformBuffer:(NSData *)inputBuffer;

- (void)cleanupThread;

@end
