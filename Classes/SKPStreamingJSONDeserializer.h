//
//  SKPStreamingJSONDeserializer.h
//  StreamingJSON
//
//  Created by Ian Baird on 12/2/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SKPStreamingJSONParser.h"

@class SKPStreamingJSONDeserializer;

@protocol SKPStreamingJSONDeserializerDelegate <NSObject>

@required
- (void)deserializer:(SKPStreamingJSONDeserializer *)sender didParse:(id)newObject;

@optional
- (void)deserializerDidComplete:(SKPStreamingJSONDeserializer *)sender;
- (void)deserializer:(SKPStreamingJSONDeserializer *)sender didFail:(NSError *)error;

@end

@interface SKPStreamingJSONDeserializer : NSObject <SKPStreamingJSONParserDelegate> 
{
    SKPStreamingJSONParser *jsonParser;
    
    id <SKPStreamingJSONDeserializerDelegate> delegate;
    
    NSMutableArray *objectStack;
    
    NSString *lastKey;
}

@property(nonatomic, assign) id <SKPStreamingJSONDeserializerDelegate> delegate;

- (id)initWithInputStream:(NSInputStream *)aStream;
- (void)start;
- (void)stop;

@end
