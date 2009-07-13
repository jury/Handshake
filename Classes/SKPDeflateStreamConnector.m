//
//  SKPGzipStreamConnector.m
//  StreamingJSON
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
