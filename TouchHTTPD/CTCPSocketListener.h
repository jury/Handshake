//
//  CTCPSocketListener.h
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

#import <Foundation/Foundation.h>
#if TARGET_OS_MAC == 1 && TARGET_OS_IPHONE == 0
#import <CoreServices/CoreServices.h>
#elif TARGET_OS_MAC == 1 && TARGET_OS_IPHONE == 1
#import <CFNetwork/CFNetwork.h>
#endif

#import "CTCPConnection.h"

@class CTCPConnection;
@protocol CTCPSocketListenerDelegate;

@interface CTCPSocketListener : NSObject <CTCPConnectionDelegate> {
    id <CTCPSocketListenerDelegate> delegate;
    uint16_t port;
    NSString *domain;
    NSString *name;
    NSString *type;
    CFSocketRef IPV4Socket;
    CFSocketRef IPV6Socket;
    NSNetService *netService;
	Class connectionClass;
	NSMutableArray *_connections;
	BOOL listening;
}

@property (readwrite, assign) id <CTCPSocketListenerDelegate> delegate;
@property (readwrite, assign) uint16_t port;
@property (readwrite, retain) NSString *domain;
@property (readwrite, retain) NSString *name;
@property (readwrite, retain) NSString *type;
@property (readonly, assign) CFSocketRef IPV4Socket;
@property (readonly, assign) CFSocketRef IPV6Socket;
@property (readonly, retain) NSNetService *netService;
@property (readwrite, assign) Class connectionClass;
@property (readonly, retain) NSArray *connections;
@property (readonly, assign) BOOL listening;

- (BOOL)start:(NSError **)outError;
- (void)stop;
- (void)serveForever;

- (BOOL)shouldHandleNewConnectionFromAddress:(NSData *)inAddress;

- (CTCPConnection *)createTCPConnectionWithAddress:(NSData *)inAddress inputStream:(NSInputStream *)inInputStream outputStream:(NSOutputStream *)inOutputStream;

- (void)connectionWillOpen:(CTCPConnection *)inConnection;
- (void)connectionDidOpen:(CTCPConnection *)inConnection;

- (void)connectionWillClose:(CTCPConnection *)inConnection;
- (void)connectionDidClose:(CTCPConnection *)inConnection;

@end

#pragma mark -

@protocol CTCPSocketListenerDelegate

@optional
- (CTCPConnection *)TCPSocketListener:(CTCPSocketListener *)inSocketListener createTCPConnectionWithAddress:(NSData *)inAddress inputStream:(NSInputStream *)inInputStream outputStream:(NSOutputStream *)inOutputStream;

@end
