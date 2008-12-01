//
//  SKPInflateStreamConnector.m
//  StreamingJSON
//
//  Created by Ian Baird on 12/1/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

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
