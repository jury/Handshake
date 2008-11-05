//
//  CTCPConnection.h
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

#import "CProtocol.h"

@protocol CTCPConnectionDelegate;

@interface CTCPConnection : CProtocol {
	id <CTCPConnectionDelegate> delegate; // Not retained.
	NSData *address;
	NSInputStream *inputStream;
	NSOutputStream *outputStream;
}

@property (readwrite, assign) id <CTCPConnectionDelegate> delegate;
@property (readonly, retain) NSData *address;
@property (readonly, retain) NSInputStream *inputStream;
@property (readonly, retain) NSOutputStream *outputStream;

- (id)initWithAddress:(NSData *)inAddress inputStream:(NSInputStream *)inInputStream outputStream:(NSOutputStream *)inOutputStream;

- (void)inputStreamHandleEvent:(NSStreamEvent)inEventCode;
- (void)outputStreamHandleEvent:(NSStreamEvent)inEventCode;

- (BOOL)open:(NSError **)outError;
- (void)close;

@end

@protocol CTCPConnectionDelegate

- (void)connectionWillOpen:(CTCPConnection *)inConnection;
- (void)connectionDidOpen:(CTCPConnection *)inConnection;

- (void)connectionWillClose:(CTCPConnection *)inConnection;
- (void)connectionDidClose:(CTCPConnection *)inConnection;

@end
