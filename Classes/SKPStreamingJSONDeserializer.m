//
//  SKPStreamingJSONDeserializer.m
//  StreamingJSON
//
//  Created by Ian Baird on 12/2/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "SKPStreamingJSONDeserializer.h"

@interface SKPStreamingJSONDeserializer ()

@property(nonatomic, retain) SKPStreamingJSONParser *jsonParser;
@property(nonatomic, retain) NSMutableArray *objectStack;
@property(nonatomic, retain) NSString *lastKey;

- (void)popObject;
- (void)pushObject:(id)newObject;

@end

@implementation SKPStreamingJSONDeserializer
@synthesize jsonParser, objectStack, lastKey, delegate;

- (id)initWithInputStream:(NSInputStream *)aStream
{
    if (self = [super init])
    {
        self.jsonParser = [[[SKPStreamingJSONParser alloc] initWithInputStream:aStream] autorelease];
        jsonParser.delegate = self;
        
        self.objectStack = [NSMutableArray array];
    }
    
    return self;
}

- (void)dealloc
{
    NSLog(@"deserializer dealloc'd");
    
    self.jsonParser = nil;
    self.objectStack = nil;
    self.lastKey = nil;
    
    [super dealloc];
}

- (void)start
{
    [jsonParser startAsynchronousParsing];
}

- (void)stop
{
    [jsonParser stopAsynchronousParsing];
}

#pragma mark -
#pragma mark private api

- (void)popObject
{
    if ([objectStack count] == 1)
    {
        [delegate deserializer:self didParse:[objectStack lastObject]];
    }
    else if ([objectStack count] > 1)
    {
        [objectStack removeLastObject];
    }
    else
    {
        NSAssert(NO, @"deserializer stack underflow");
    }
}

- (void)pushObject:(id)newObject
{
    id lastObject = [objectStack lastObject];
    
    if ([lastObject isKindOfClass:[NSMutableDictionary class]])
    {
        NSAssert(lastKey, @"No key parsed!");
        
        [lastObject setObject:newObject forKey:lastKey];
    }
    else if ([lastObject isKindOfClass:[NSMutableArray class]])
    {
        [lastObject addObject:newObject];
    }

    [objectStack addObject:newObject];    
}

#pragma mark -
#pragma mark SKPStreamingJSONParserDelegate

- (BOOL)parserFoundNull:(SKPStreamingJSONParser *)sender
{
    // NSLog(@"parser found null");
    
    [self pushObject:[NSNull null]];
    [self popObject];
    
    return YES;
}

- (BOOL)parser:(SKPStreamingJSONParser *)sender foundBool:(BOOL)value
{
    // NSLog(@"parser found bool: %d", value);
    
    [self pushObject:[NSNumber numberWithBool:value]];
    [self popObject];
    
    return YES;
}

- (BOOL)parser:(SKPStreamingJSONParser *)sender foundNumber:(NSDecimalNumber *)value
{
    // NSLog(@"parser found number: %@", value);
    
    [self pushObject:value];
    [self popObject];
    
    return YES;
}

- (BOOL)parser:(SKPStreamingJSONParser *)sender foundString:(NSString *)value
{
    // NSLog(@"parser found string: %@", value);
    
    [self pushObject:value];
    [self popObject];
    
    return YES;
}

- (BOOL)parser:(SKPStreamingJSONParser *)sender foundKey:(NSString *)value
{
    //NSLog(@"parser found key: %@", value);
    
    self.lastKey = value;
    
    return YES;
}

- (BOOL)parserDidStartDictionary:(SKPStreamingJSONParser *)sender
{
    //NSLog(@"parser starting dictionary");
    
    [self pushObject:[NSMutableDictionary dictionary]];
    
    return YES;
}

- (BOOL)parserDidEndDictionary:(SKPStreamingJSONParser *)sender
{
    //NSLog(@"parser ending dictionary");
    
    [self popObject];
    
    self.lastKey = nil;
    
    return YES;
}

- (BOOL)parserDidStartArray:(SKPStreamingJSONParser *)sender
{
    //NSLog(@"parser starting array");
    
    [self pushObject:[NSMutableArray array]];
    
    return YES;
}

- (BOOL)parserDidEndArray:(SKPStreamingJSONParser *)sender
{
    //NSLog(@"parser ending array");
    
    [self popObject];
    
    return YES;
}

- (void)parserDidComplete:(SKPStreamingJSONParser *)sender
{
    if ([delegate respondsToSelector:@selector(deserializerDidComplete:)])
    {
        [delegate deserializerDidComplete:self];
    }
}

- (void)parser:(SKPStreamingJSONParser *)sender didFail:(NSError *)error
{
    if ([delegate respondsToSelector:@selector(deserializer:didFail:)])
    {
        [delegate deserializer:self didFail:error];
    }
}


@end
