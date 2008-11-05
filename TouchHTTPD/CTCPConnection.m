//
//  CTCPConnection.m
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

#import "CTCPConnection.h"

@interface CTCPConnection ()
@property (readwrite, retain) NSData *address;
@property (readwrite, retain) NSInputStream *inputStream;
@property (readwrite, retain) NSOutputStream *outputStream;
@end

@implementation CTCPConnection

@synthesize delegate;
@synthesize address;
@synthesize inputStream;
@synthesize outputStream;

- (id)initWithAddress:(NSData *)inAddress inputStream:(NSInputStream *)inInputStream outputStream:(NSOutputStream *)inOutputStream
{
if ((self = [self init]) != NULL)
	{
	self.address = inAddress;
	self.inputStream = inInputStream;
	self.outputStream = inOutputStream;
	
	self.inputStream.delegate = self;
	self.outputStream.delegate = self;
	}
return(self);
}

- (void)dealloc
{
self.delegate = NULL;
self.address = NULL;
self.inputStream = NULL;
self.outputStream = NULL;

[super dealloc];
}

- (BOOL)open:(NSError **)outError
{
#pragma unused (outError)

[self.delegate connectionWillOpen:self];

[self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];
[self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];

[self.inputStream open];
[self.outputStream open];

[self.delegate connectionDidOpen:self];

return(YES);
}

- (void)close
{
[self.delegate connectionWillClose:self];

[self.inputStream close];
[self.outputStream close];

[self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];
[self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];

self.inputStream.delegate = NULL;
self.outputStream.delegate = NULL;

[self.delegate connectionDidClose:self];
}

#pragma mark -

/*
- (size_t)writeData:(NSData *)inData
{
NSUInteger theBufferLength = inData.length;
if (theBufferLength > 0)
	{
	UInt8 *thePtr = inData.mutableBytes;
	NSInteger theBytesWritten = [self.outputStream write:thePtr maxLength:theBufferLength];
	if (theBytesWritten == theBufferLength)
		{
		inData.length = 0;
		}
	else if (theBytesWritten > 0)
		{
		inData = [NSMutableData dataWithBytes:thePtr + theBytesWritten length:theBufferLength - theBytesWritten];
		}
	else if (theBytesWritten <= 0)
		{
		// TODO Not totally sure what to do here. Ignoring the error seems to be a good idea. Can easily cause this code to be hit by using the webcam sample and hitting reload a lot.
//			[NSException raise:NSGenericException format:@"flushOutputBuffer failed with %d", theBytesWritten];
		}
	}
}
*/


- (void)stream:(NSStream *)inStream handleEvent:(NSStreamEvent)inEventCode
{
if (inEventCode == NSStreamEventEndEncountered)
	{
	[self close];
	}
else
	{
	if (inStream == self.inputStream)
		{
		[self inputStreamHandleEvent:inEventCode];
		}
	else if (inStream == self.outputStream)
		{
		[self outputStreamHandleEvent:inEventCode];
		}
	else
		{
		NSAssert(NO, @"TODO");
		}
	}
}

- (void)inputStreamHandleEvent:(NSStreamEvent)inEventCode
{
if (inEventCode == NSStreamEventHasBytesAvailable)
	{
	NSData *theData = NULL;
	uint8_t *theBufferPtr = NULL;
	NSInteger theBufferLength = 0;
	BOOL theResult = [self.inputStream getBuffer:&theBufferPtr length:(NSUInteger *)&theBufferLength];
	if (theResult == YES)
		{
		theData = [NSData dataWithBytesNoCopy:theBufferPtr length:theBufferLength freeWhenDone:NO];
		}
	else if (theResult == NO)
		{
		NSMutableData *theMutableData = [NSMutableData dataWithLength:1024];
		theBufferLength = [self.inputStream read:theMutableData.mutableBytes maxLength:theMutableData.length];
		if (theBufferLength <= 0)
			{
			NSLog(@"TODO read returned %d (%d)", theBufferLength, self.inputStream.hasBytesAvailable);
			return;
			}
		theMutableData.length = theBufferLength;
		theData = theMutableData;
		}

	[self dataReceived:theData];
	}
}

- (void)outputStreamHandleEvent:(NSStreamEvent)inEventCode
{
#pragma unused (inEventCode)
NSLog(@"You should probably override outputStreamHandleEvent:");
}

@end
