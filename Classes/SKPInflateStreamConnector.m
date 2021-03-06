//
//  SKPInflateStreamConnector.m
//  StreamingJSON
//
//  Created by Ian Baird on 12/1/08.
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

#import "SKPInflateStreamConnector.h"


@implementation SKPInflateStreamConnector

- (id)initWithUpstream:(NSInputStream *)aStream
{
    if (self = [super initWithUpstream:aStream])
    {
        /* allocate deflate state */
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        strm.opaque = Z_NULL;
        strm.total_out = 0;
        inflateInit(&strm);
    }
    
    return self;
}

- (void)dealloc
{
    [self cleanupThread];
    
    inflateEnd(&strm);
    
    [super dealloc];
}

- (NSData *)transformBuffer:(NSData *)inputBuffer
{
	if ([inputBuffer length] == 0) return [[inputBuffer retain] autorelease];
    
	unsigned full_length = [inputBuffer length];
	unsigned half_length = [inputBuffer length] / 2;
    
	NSMutableData *decompressed = [[NSMutableData alloc] initWithLength:full_length + half_length];
	int status;

	strm.next_in = (Bytef *)[inputBuffer bytes];
	strm.avail_in = [inputBuffer length];
	
    uLong savedTotalOut = strm.total_out;
    
	while (strm.avail_in > 0)
	{
		// Make sure we have enough room and reset the lengths.
		if (strm.total_out >= [decompressed length])
			[decompressed increaseLengthBy: half_length];
		strm.next_out = [decompressed mutableBytes] + (strm.total_out - savedTotalOut);
		strm.avail_out = [decompressed length] - (strm.total_out - savedTotalOut);
        
		// Inflate another chunk.
		status = inflate (&strm, Z_SYNC_FLUSH);
		if (status != Z_OK)
        {
            NSLog(@"error decompressing stream: %s", strm.msg);
            [decompressed release];
            return nil;
        }
	}
    
	// Set real length.
    [decompressed setLength: (strm.total_out - savedTotalOut)];
    NSData *retData = [[decompressed copy] autorelease];
    [decompressed release];
      
    return retData;
}


@end
