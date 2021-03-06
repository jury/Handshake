//
//  SKPInputStreamConnector.m
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

#import "SKPInputStreamConnector.h"

#import "HSK_CFUtilities.h"

@interface SKPInputStreamConnector ()

@property(nonatomic, retain, readwrite) NSInputStream *upstreamStream;
@property(nonatomic, retain, readwrite) NSInputStream *downstreamStream;
@property(nonatomic, retain, readwrite) NSOutputStream *internalStream;

@property(retain) NSRunLoop *workerRunLoop;
@property(retain) NSThread *workerThread;

@property(nonatomic, assign) CFHTTPMessageRef response;

@end

@implementation SKPInputStreamConnector

@synthesize upstreamStream, downstreamStream, internalStream, workerRunLoop, workerThread, delegate, response;

- (id)initWithUpstream:(NSInputStream *)aStream
{
    if (self = [super init])
    {
        [NSStream createPairWithUNIXSocketPairWithInputStream:&downstreamStream outputStream:&internalStream];
        
        [downstreamStream retain];
        [internalStream retain];
        
        self.upstreamStream = aStream;
        
        workerThread = [[NSThread alloc] initWithTarget:self selector:@selector(runLoopThread:) object:nil];
        [workerThread start];
    }
    
    return self;
}

- (void)cleanupThread
{
    if ([self.workerThread isFinished])
        return;
    
    CFRunLoopRef tmpWorkerRunLoop = [self.workerRunLoop getCFRunLoop];
    if (tmpWorkerRunLoop)
    {
        CFRetain(tmpWorkerRunLoop);
    }
    
    [self.workerThread cancel];
    
    if (tmpWorkerRunLoop)
    {
        NSLog(@"*** stopping worker run loop");
        CFRunLoopStop(tmpWorkerRunLoop);
        CFRelease(tmpWorkerRunLoop);
    }
    
    while (![self.workerThread isFinished])
    {
        
        NSLog(@"*** waiting on worker thread death");
        [NSThread sleepForTimeInterval:0.1];
    }
    
    self.workerThread = nil;
    
    self.workerRunLoop = nil;
}    
    

- (void)dealloc
{
    NSLog(@"connector dealloc'd");
    
    [self cleanupThread];
    
    self.upstreamStream = nil;
    self.downstreamStream = nil;
    
    self.internalStream = nil;
    
    if (self.response)
    {
        CFRelease(response);
        self.response = nil;
    }
    
    [super dealloc];
}

- (NSData *)transformBuffer:(NSData *)inputBuffer
{
    // Override this in the subclass
    
    static NSInteger totalBytes = 0;
    
    totalBytes += [inputBuffer length];
    
    NSLog(@"OVERRIDE ME! *** transformed %d bytes...", totalBytes);
    
    return [[inputBuffer copy] autorelease];
}

- (void)runLoopThread:(id)dummy
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [upstreamStream setDelegate:self];
    [upstreamStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [upstreamStream open];
    
    [internalStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [internalStream open];
    
    self.workerThread = [NSThread currentThread];
    self.workerRunLoop = [NSRunLoop currentRunLoop];
    
    NSLog(@"*** worker thread start");
    
    while (![[NSThread currentThread] isCancelled])
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    NSLog(@"*** worker thread cleanup");
    
    self.workerRunLoop = nil;
    
    [internalStream close];
    [internalStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    [upstreamStream close];
    [upstreamStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [upstreamStream setDelegate:nil];
    
    [pool drain];
}

- (void)stream:(NSInputStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    switch(streamEvent)
    {
        case NSStreamEventOpenCompleted:
        {
            if ([delegate respondsToSelector:@selector(connector:didCompleteUpstreamOpen:)])
            {
                [delegate connector:self didCompleteUpstreamOpen:theStream];
            }
            break;
        }
        case NSStreamEventHasBytesAvailable:
        {
            // See if the header has been parsed
            
            if (!self.response)
            {
                self.response = (CFHTTPMessageRef) CFReadStreamCopyProperty((CFReadStreamRef)theStream, kCFStreamPropertyHTTPResponseHeader);
                
                if (response && [delegate respondsToSelector:@selector(connector:didParseHTTPResponse:)])
                {
                    if (![delegate connector:self didParseHTTPResponse:response])
                    {
                        // delegate does not want to continue
                        [[NSThread currentThread] cancel];
                        break;
                    }
                }
            }
            
            // Read from the upstream
            uint8_t buffer[4096];
            
            NSInteger bytesRead;
            
            // Go blocking for a while (this allows us to consume reads in order
            [upstreamStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            
            do
            {
                bytesRead = [theStream read:buffer maxLength:4096];
                
                if (bytesRead < 0)
                {
                    NSLog(@"error reading stream: %@", [theStream streamError]);
                    
                    [[NSThread currentThread] cancel];
                    
                    if ([delegate respondsToSelector:@selector(connector:didFail:)])
                    {
                        [delegate connector:self didFail:[theStream streamError]];
                    }
                    
                    break;
                }
                else if (bytesRead == 0)
                {
                    [[NSThread currentThread] cancel];
                    
                    if ([delegate respondsToSelector:@selector(connectorDidComplete:)])
                    {
                        [delegate connectorDidComplete:self];
                    }
                    
                    break;
                }
                else
                {
                    // TODO: pass buffer out to delegate for transformation here
                    NSData *dataToTransform = [[NSData alloc] initWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO];
                    NSData *transformedData = [self transformBuffer:dataToTransform];
                    [dataToTransform release];
                    
                    uint8_t *writePtr = (uint8_t *)[transformedData bytes];
                    // write into the internal output stream
                    uint8_t *writePtrEnd = writePtr + [transformedData length];
                    
                    while (writePtr < writePtrEnd)
                    {
                        // Pump the runloop if we need space to open up
                        while (![internalStream hasSpaceAvailable])
                        {
                            NSLog(@"*** internal stream waiting on write");
                            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantPast]];
                        }
                        
                        NSInteger bytesWritten = [internalStream write:writePtr maxLength:writePtrEnd - writePtr];
                        if (bytesWritten < 0)
                        {          
                            NSError *error = [[internalStream streamError] retain];
                            NSLog(@"*** error writing internal stream: %@", error);
                            
                            [[NSThread currentThread] cancel];
                            
                            // Go back to async
                            [upstreamStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
                            
                            if ([delegate respondsToSelector:@selector(connector:didFail:)])
                            {
                                [delegate connector:self didFail:error];
                            }
                            
                            [error release];
                            
                            return;
                        }
                        
                        writePtr += bytesWritten;
                    }
                }
            } while ([upstreamStream hasBytesAvailable]);
            
            // Go back to async
            [upstreamStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];   
            
            break;
        }
        case NSStreamEventEndEncountered:
        {
            NSLog(@"upstream closed in connector");
            
            [[NSThread currentThread] cancel];
            
            if ([delegate respondsToSelector:@selector(connectorDidComplete:)])
            {
                [delegate connectorDidComplete:self];
            }            
            
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"upstream closed in connector");
            
            [[NSThread currentThread] cancel];
            
            if ([delegate respondsToSelector:@selector(connector:didFail:)])
            {
                [delegate connector:self didFail:[theStream streamError]];
            }
            
            break;
        }
    }
}

@end
