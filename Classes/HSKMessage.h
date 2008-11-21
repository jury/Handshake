//
//  HSKMessage.h
//  Handshake
//
//  Created by Ian Baird on 11/16/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RPSNetworkPeer;

// TODO: implement NSCoder support

@interface HSKMessage : NSObject 
{
    NSString *type;
    NSString *cookie;
    NSString *version;
    
    NSString *wrappedType;
    NSArray  *listenAddrs;
    BOOL isDeclined;
    
    RPSNetworkPeer *fromPeer;
    
    id data;
}

@property(nonatomic, retain) NSString *type;
@property(nonatomic, retain) NSString *wrappedType;
@property(nonatomic, retain) NSString *cookie;
@property(nonatomic, retain) NSString *version;
@property(nonatomic, retain) NSArray  *listenAddrs;

@property(nonatomic, assign) BOOL isDeclined;

@property(nonatomic, retain) RPSNetworkPeer *fromPeer;

@property(nonatomic, retain) id data;

+ (NSString *)generateCookie;

+ (id)message;
+ (id)messageWithDictionaryRepresentation:(NSDictionary *)dictionary;

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionary;

- (NSDictionary *)dictionaryRepresentation;

@end
