//
//  SKPGzipStreamConnector.m
//  StreamingJSON
//
//  Created by Ian Baird on 11/30/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "SKPDeflateStreamConnector.h"

@implementation SKPDeflateStreamConnector

- (id)initWithUpstream:(NSInputStream *)aStream
{
    if (self = [super initWithUpstream:aStream])
    {
        /* allocate deflate state */
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        strm.opaque = Z_NULL;
        strm.total_out = 0;
        deflateInit(&strm, Z_BEST_COMPRESSION);
    }
    
    return self;
}

- (void)dealloc
{
    [self cleanupThread];
    
    deflateEnd(&strm);
    
    [super dealloc];
}

- (NSData *)transformBuffer:(NSData *)inputBuffer
{
    NSMutableData *compressed = [[NSMutableData alloc] initWithLength:deflateBound(&strm, [inputBuffer length])];
    
    uLong startingTotalOut = strm.total_out;
    
    strm.next_in = (Bytef *)[inputBuffer bytes];
    strm.avail_in = [inputBuffer length];
    
    strm.next_out = [compressed mutableBytes];
    strm.avail_out = [compressed length];
    
    deflate(&strm, Z_SYNC_FLUSH);
    
    [compressed setLength: (strm.total_out - startingTotalOut)];
    NSData *retData = [[compressed copy] autorelease];
    [compressed release];
        
    return retData;
}

@end
