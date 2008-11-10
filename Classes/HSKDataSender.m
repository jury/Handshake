//
//  HSKDataSender.m
//  Handshake
//
//  Created by Ian Baird on 11/9/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKDataSender.h"

@interface HSKDataSender ()

@property(nonatomic, retain) NSData *dataToSend;
@property(nonatomic, retain) NSString *hostAddress;
@property(nonatomic, retain) NSNumber *port;
@property(nonatomic, retain) NSString *cookie;
@property(nonatomic, retain) NSString *type;
@property(nonatomic, retain) NSStream *inStream;
@property(nonatomic, retain) NSStream *outStream;

@end

@implementation HSKDataSender

@synthesize delegate, dataToSend, hostAddress, port, cookie, type, inStream, outStream;

- (id)initWithDataToSend:(NSData *)aDataToSend ofType:(NSString *)aType withCookie:(NSString *)aCookie toAddress:(NSString *)aHostAddress port:(NSNumber *)aPort
{
    if (self = [super init])
    {
        self.dataToSend = aDataToSend;
        self.type = aType;
        self.cookie = aCookie;
        self.hostAddress = aHostAddress;
        self.port = aPort;
    }
    
    return self;
}

- (void)dealloc
{
    self.dataToSend = nil;
    self.type = nil;
    self.cookie = nil;
    self.hostAddress = nil;
    self.port = nil;
    self.inStream = nil;
    self.outStream = nil;
    
    [super dealloc];
}

- (void)start
{
}

- (void)cancel
{
}

@end
