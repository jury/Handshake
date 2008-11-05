//
//  HSKDataServer.m
//  Handshake
//
//  Created by Ian Baird on 11/4/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKDataServer.h"
#import "HSKDataConnection.h"

@implementation HSKDataServer

@synthesize socketListener;

- (void)dealloc
{
    self.socketListener = nil;
    
    [super dealloc];
}

- (void)createDefaultSocketListener
{
    if (self.socketListener == nil)
	{
        CTCPSocketListener *theSocketListener = [[[CTCPSocketListener alloc] init] autorelease];
        theSocketListener.type = @"_hskdata._tcp.";
        theSocketListener.port = 0; // allow the kernel to setup our port
        theSocketListener.delegate = self;
        
        self.socketListener = theSocketListener;
	}
}

- (CTCPConnection *)TCPSocketListener:(CTCPSocketListener *)inSocketListener createTCPConnectionWithAddress:(NSData *)inAddress inputStream:(NSInputStream *)inInputStream outputStream:(NSOutputStream *)inOutputStream;
{
    CTCPConnection *theTCPConnection = [[[CBufferedTCPConnection alloc] initWithAddress:inAddress inputStream:inInputStream outputStream:inOutputStream] autorelease];
    theTCPConnection.delegate = inSocketListener;
    
    CProtocol *theLowerLink = theTCPConnection;
    
    HSKDataConnection *theDataConnection = [[[HSKDataConnection alloc] init] autorelease];
    theDataConnection.lowerLink = theLowerLink;
    theLowerLink.upperLink = theDataConnection;
    
    return(theTCPConnection);
}


@end
