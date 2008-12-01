//
//  SKPInputStreamConnector.h
//  Handshake
//
//  Created by Ian Baird on 11/30/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SKPInputStreamConnector : NSObject 
{
    NSInputStream *upstreamStream;
    
    NSInputStream *downstreamStream;
    NSOutputStream *internalStream;
    
    NSRunLoop *workerRunLoop;
    NSThread *workerThread;
}

@property(nonatomic, retain, readonly) NSInputStream *upstreamStream;
@property(nonatomic, retain, readonly) NSInputStream *downstreamStream;

- (id)initWithUpstream:(NSInputStream *)aStream;
- (NSData *)transformBuffer:(NSData *)inputBuffer;

- (void)cleanupThread;

@end
