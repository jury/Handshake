//
//  HSKDataSender.m
//  Handshake
//
//  Created by Ian Baird on 11/9/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKDataClient.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/fcntl.h>
#include <arpa/inet.h>
#include <netinet/in.h>


#define CONNECT_TIMEOUT 5.0
#define SEND_CHUNK_SIZE 4096

@interface HSKDataClient ()

@property(nonatomic, retain) NSInputStream *inStream;
@property(nonatomic, retain) NSOutputStream *outStream;
@property(nonatomic, retain) NSTimer *livenessTimer;

@property(nonatomic, assign) BOOL completed;
@property(nonatomic, assign) NSUInteger dataToSendOffset;

- (void)doCleanupStreams;
- (BOOL)doConnectToAddr:(struct sockaddr_in *)sin;
- (void)sendNextChunk;

@end

@implementation HSKDataClient

@synthesize delegate, dataToSend, hostAddrs, inStream, outStream, livenessTimer, completed, dataToSendOffset;

#pragma mark -
#pragma mark ctor/dtor

- (id)init
{
    if (self = [super init])
    {
        self.hostAddrs = [NSMutableArray array];
    }
    
    return self;
}

- (void)dealloc
{
    self.dataToSend = nil;
    self.hostAddrs = nil;
    
    [self doCleanupStreams];
    
    [self.livenessTimer invalidate];
    self.livenessTimer = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark public api

- (BOOL)start
{
    BOOL success = NO;
    
    NSAssert(dataToSend, @"must set dataToSend!");
    NSAssert(hostAddrs, @"must set hostAddrs!");
    NSAssert(!inStream, @"already set inStream!");
    NSAssert(!outStream, @"already set outStream!");
    NSAssert(!completed, @"already completed!");
    
    self.completed = NO;
    
    for (NSDictionary *hostAddr in self.hostAddrs)
    {
        struct sockaddr_in sin;
        memset(&sin, 0, sizeof(sin));
        NSString *dottedQuad = [hostAddr objectForKey:@"dottedquad"];
        NSNumber *port = [hostAddr objectForKey:@"port"];
        inet_aton([dottedQuad UTF8String], &(sin.sin_addr));
        sin.sin_port = htons([port unsignedShortValue]);
        sin.sin_family = AF_INET;
        sin.sin_len = sizeof(sin);
        
        if ([self doConnectToAddr:&sin])
        {
            success = YES;
            break;
        }
    }
    
    if (!success)
    {
        NSLog(@"unable to connect to any address, trying server transfer");
    }
    
    return success;
}

- (void)cancel
{
    [self doCleanupStreams];
    
    if (!self.completed)
    {
        self.completed = YES;
        
        [delegate dataClientFail:self];
    }
}

#pragma mark -
#pragma mark internal methods

- (BOOL)doConnectToAddr:(struct sockaddr_in *)sin
{
    int fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (fd < 0)
    {
        [NSException raise:@"HSKDataClientException" format:@"Unable to create! (%d)", errno];
    }
    
    int flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
    
    int n = connect(fd, (struct sockaddr*)sin, sizeof(struct sockaddr_in));    
    if (n != 0) 
    {
        if (errno != EINPROGRESS)
        {
            NSLog(@"failed to connect: %d", errno);
            // unable to connect to the server, go to the next on the list
            close(fd);
            
            return NO;
        }
        else
        {
            fd_set wset, rset;
            struct timeval tval;
            int ticks = 0;
            int maxticks = CONNECT_TIMEOUT / 0.1;
            while (ticks < maxticks)
            {
                FD_ZERO(&rset);
                FD_SET(fd, &rset);
                wset = rset;
                tval.tv_sec = 0;
                tval.tv_usec = 0;
                n = select(fd + 1, &rset, &wset, NULL, &tval);
                if (n == 0)
                {
                    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, true);
                }
                else if (n < 0)
                {
                    NSLog(@"failed on select: %d", errno);
                    close(fd);
                    return NO;
                }
                else
                {
                    int err = 0;
                    socklen_t len = sizeof(err);
                    if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &len) < 0)
                    {
                        NSLog(@"failed to connect, error in select");
                        close(fd);
                        return NO;
                    }
                    if (err != 0)
                    {
                        NSLog(@"failed to connect: %d", err);
                        close(fd);
                        return NO;
                    }
                    break;
                }
                ++ticks;
            }
            
            if (n == 0)
            {
                // Timed out, try the next server on the list
                NSLog(@"timed out on connect");
                close(fd);
                return NO;
            }
            
            // We're connected here
        }
    }
    
    // Reset the flags on the socket
    flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags & ~O_NONBLOCK);
    
    // Try to open some streams
    
    CFStreamCreatePairWithSocket(NULL, fd, (CFReadStreamRef*)&inStream, (CFWriteStreamRef*)&outStream);
    
    if (!inStream || !outStream)
    {
        [inStream release];
        [outStream release];
        
        shutdown(fd, SHUT_RDWR);
        close(fd);
        
        // Failed to setup streams, try next server on the list
        NSLog(@"failed to setup streams");
        return NO;
    }
    
    // Close the socket when we're done
    CFReadStreamSetProperty((CFReadStreamRef)inStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty((CFWriteStreamRef)outStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    [inStream retain];
    [outStream retain];
    
    [inStream setDelegate:self];
    [outStream setDelegate:self];
    
    [inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    [inStream open];
    [outStream open];
        
    return YES;
}

- (void)doCleanupStreams
{
    [inStream close];
    [outStream close];
    
    [inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    self.inStream = nil;
    self.outStream = nil;    
}

- (void)sendNextChunk
{    
    NSUInteger bytesToSend = (SEND_CHUNK_SIZE > ([dataToSend length] - dataToSendOffset)) ? ([dataToSend length] - dataToSendOffset) : SEND_CHUNK_SIZE;
    
    void *bufferStart = (void *)[dataToSend bytes] + dataToSendOffset;    

    NSInteger bytesWritten = [outStream write:bufferStart maxLength:bytesToSend];

    dataToSendOffset += bytesWritten;
    
    if (dataToSendOffset >= [dataToSend length])
    {
        self.completed = YES;
        
        [delegate dataClient:self progress:1.0];
        
        [delegate dataClientComplete:self];
    }
    else
    {
        [delegate dataClient:self progress:(CGFloat)dataToSendOffset / (CGFloat)[dataToSend length]];
    }    
}

#pragma mark -
#pragma mark timer methods

- (void)livenessCheck:(NSTimer *)aTimer
{    
    [self cancel];
}

#pragma mark -
#pragma mark NSStream delegate method

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    switch(streamEvent)
    {
        case NSStreamEventEndEncountered:
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"closing socket");
            [self cancel];
            break;
        case NSStreamEventHasSpaceAvailable:
            [self sendNextChunk];
            break;
        case NSStreamEventHasBytesAvailable:
            NSLog(@"received bytes back from the server, how bizarre!");
            break;
    }
}

@end
