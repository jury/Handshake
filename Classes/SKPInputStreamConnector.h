//
//  SKPInputStreamConnector.h
//  Handshake
//
//  Created by Ian Baird on 11/30/08.
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
