//
//  HSKDataConnection.m
//  Handshake
//
//  Created by Ian Baird on 11/4/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKBypassConnection.h"


@implementation HSKBypassConnection

- (void)dataReceived:(NSData *)inData
{
    NSString *theString = [[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease];
    NSLog(@"%@", theString);
    
    theString = [NSString stringWithFormat:@"Hello World (%@)", theString];
    NSData *theData = [theString dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendData:theData];
}

@end
