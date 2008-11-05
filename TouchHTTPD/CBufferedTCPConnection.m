//
//  CBufferedTCPConnection
//  TouchHTTP
//
//  Created by Jonathan Wight on 03/11/08.
//  Copyright (c) 2008 Jonathan Wight
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "CBufferedTCPConnection.h"

@interface CBufferedTCPConnection ()
@property (readwrite, retain) NSMutableData *outputBuffer;

- (void)flushOutputBuffer;
@end

@implementation CBufferedTCPConnection

@synthesize outputBuffer;
@synthesize bufferOutput;

- (id)init
{
if ((self = [super init]) != NULL)
	{
	self.outputBuffer = [NSMutableData data];
	}
return self;
}

- (void)dealloc
{
self.outputBuffer = NULL;
//
[super dealloc];
}

- (void)outputStreamHandleEvent:(NSStreamEvent)inEventCode
{
if (inEventCode == NSStreamEventHasSpaceAvailable || inEventCode == NSStreamEventHasBytesAvailable)
	{
	[self flushOutputBuffer];
	}
}

/*
- (void)dataReceived:(NSData *)inData;
{
#pragma unused (inData)
NSLog(@"You should probably override dataReceived:");
}
*/

- (size_t)sendData:(NSData *)inData
{
[self.outputBuffer appendData:inData];
[self flushOutputBuffer];
return(inData.length);
}

- (void)flushOutputBuffer
{
if ([self.outputStream hasSpaceAvailable] == NO)
	{
	return;
	}
NSUInteger theBufferLength = self.outputBuffer.length;
if (theBufferLength > 0)
	{
	UInt8 *thePtr = self.outputBuffer.mutableBytes;
	NSInteger theBytesWritten = [self.outputStream write:thePtr maxLength:theBufferLength];
	if (theBytesWritten == theBufferLength)
		{
		self.outputBuffer.length = 0;
		}
	else if (theBytesWritten >= 0)
		{
		NSLog(@"* Couldn't write everything to outputstream, storing rest in buffer.");
		self.outputBuffer = [NSMutableData dataWithBytes:thePtr + theBytesWritten length:theBufferLength - theBytesWritten];
		}
	}
}

@end
