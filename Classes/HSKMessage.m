//
//  HSKMessage.m
//  Handshake
//
//  Created by Ian Baird on 11/16/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKMessage.h"

#import "HSKMessageDefines.h"

@implementation HSKMessage

@synthesize type, wrappedType, cookie, version, listenAddrs, fromPeer, data;

+ (NSString *)generateCookie
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    
    NSString *uuidString = (NSString *)CFUUIDCreateString(NULL, uuidRef);
    
    CFRelease(uuidRef);
    
    return [uuidString autorelease];
}

+ (id)message
{
    return [[[HSKMessage alloc] init] autorelease];
}

+ (id)messageWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    return [[[HSKMessage alloc] initWithDictionaryRepresentation:dictionary] autorelease];
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dictionary
{
    if (self = [super init])
    {
        self.cookie = [dictionary objectForKey:kHSKMessageCookieKey];
        self.type = [dictionary objectForKey:kHSKMessageTypeKey];
        self.wrappedType = [dictionary objectForKey:kHSKMessageWrappedTypeKey];
        self.version = [dictionary objectForKey:kHSKMessageVersionKey];
        self.data = [dictionary objectForKey:kHSKMessageDataKey];
        self.listenAddrs = [dictionary objectForKey:kHSKMessageListenAddrsKey];
        
        NSAssert(cookie, @"must set cookie!");
        NSAssert(type, @"must set type!");
        NSAssert(version, @"must set version");
    }
    
    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    if (cookie)
    {
        [message setObject:cookie forKey:kHSKMessageCookieKey];
    }
    else
    {
        NSAssert(NO, @"must set cookie!");
    }
    
    if (type)
    {
        [message setObject:type forKey:kHSKMessageTypeKey];
    }
    else
    {
        NSAssert(NO, @"must have type!");
    }
    
    if (wrappedType)
    {
        [message setObject:wrappedType forKey:kHSKMessageWrappedTypeKey];
    }
    
    if (version)
    {
        [message setObject:version forKey:kHSKMessageVersionKey];
    }
    else
    {
        NSAssert(NO, @"must include version!");
    }
    
    if (data)
    {
        [message setObject:data forKey:kHSKMessageDataKey];
    }
    
    if (listenAddrs)
    {
        [message setObject:listenAddrs forKey:kHSKMessageListenAddrsKey];
    }

    return [[message copy] autorelease];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"HSKMessage <%p> : cookie = %@ type = %@ wrappedType = %@ version = %@ listenAddrs = %@\ndata = %@",
            (void*)self, cookie, type, wrappedType, version, listenAddrs, data];
}

@end
