/*
 *  HSK_CFUtilities.m
 *  Handshake
 *
 *  Created by Ian Baird on 11/26/08.
 *  Copyright 2008 Skorpiostech, Inc. All rights reserved.
 *
 */

#include "HSK_CFUtilities.h"

#include <sys/types.h>
#include <sys/socket.h>

void CFStreamCreatePairWithUNIXSocketPair(CFAllocatorRef alloc, CFReadStreamRef *readStream, CFWriteStreamRef *writeStream)
{
    int sockpair[2];
    int success = socketpair(AF_UNIX, SOCK_STREAM, 0, sockpair);
    if (success < 0)
    {
        [NSException raise:@"HSK_CFUtilitiesErrorDomain" format:@"Unable to create socket pair, errno: %d", errno];
    }
    
    CFStreamCreatePairWithSocket(NULL, sockpair[0], readStream, NULL);
    CFReadStreamSetProperty(*readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFStreamCreatePairWithSocket(NULL, sockpair[1], NULL, writeStream);    
    CFWriteStreamSetProperty(*writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
}

CFIndex CFWriteStreamWriteFully(CFWriteStreamRef outputStream, const uint8_t* buffer, CFIndex length)
{
    CFIndex bufferOffset = 0;
    CFIndex bytesWritten;

    // NSLog(@"WRITE: %@", [[[NSString alloc] initWithBytesNoCopy:buffer length:length encoding:NSUTF8StringEncoding freeWhenDone:NO] autorelease]);
    
    while (bufferOffset < length)
    {
        if (CFWriteStreamCanAcceptBytes(outputStream))
        {
            bytesWritten = CFWriteStreamWrite(outputStream, &(buffer[bufferOffset]), length - bufferOffset);
            if (bytesWritten < 0)
            {
                // Bail!
                return bytesWritten;
            }
            bufferOffset += bytesWritten;
        }
        else if (CFWriteStreamGetStatus(outputStream) == kCFStreamStatusError)
        {
            [NSException raise:@"HSK_CFUtilitiesErrorDomain" format:@"Error writing bytes to stream!"];
        }
        else
        {
            // Pump the runloop
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.0, true);
        }
    }
    
    return bufferOffset;
}

@implementation NSStream (HSK_CFUtilities)

+ (void) createPairWithUNIXSocketPairWithInputStream:(NSInputStream **)inputStream outputStream:(NSOutputStream **)outputStream
{
    CFStreamCreatePairWithUNIXSocketPair(NULL, (CFReadStreamRef *)&inputStream, (CFWriteStreamRef *)&outputStream);
    
    [*inputStream autorelease];
    [*outputStream autorelease];
}

@end

@implementation NSOutputStream (HSK_CFUtilities)

- (NSInteger)writeFully:(const uint8_t *)buffer maxLength:(NSUInteger)length
{
    return CFWriteStreamWriteFully((CFWriteStreamRef)self, buffer, length);
}

@end

