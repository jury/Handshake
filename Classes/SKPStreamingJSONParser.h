//
//  SKPStreamingJSONParser.h
//  StreamingJSON
//
//  Created by Ian Baird on 11/29/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "yajl_parse.h"

@class SKPStreamingJSONParser;

@protocol SKPStreamingJSONParserDelegate <NSObject>

@optional
- (BOOL)parserFoundNull:(SKPStreamingJSONParser *)sender;
- (BOOL)parser:(SKPStreamingJSONParser *)sender foundBool:(BOOL)value;
- (BOOL)parser:(SKPStreamingJSONParser *)sender foundNumber:(NSDecimalNumber *)value;
- (BOOL)parser:(SKPStreamingJSONParser *)sender foundString:(NSString *)value;
- (BOOL)parser:(SKPStreamingJSONParser *)sender foundKey:(NSString *)value;
- (BOOL)parserDidStartDictionary:(SKPStreamingJSONParser *)sender;
- (BOOL)parserDidEndDictionary:(SKPStreamingJSONParser *)sender;
- (BOOL)parserDidStartArray:(SKPStreamingJSONParser *)sender;
- (BOOL)parserDidEndArray:(SKPStreamingJSONParser *)sender;

@end

@interface SKPStreamingJSONParser : NSObject 
{
    yajl_handle yajlHandle;
    
    NSInputStream *inputStream;
    
    BOOL isFinished;
    BOOL isParsing;
    
    id <SKPStreamingJSONParserDelegate> delegate;
    
    NSError *parserError;
}

@property(nonatomic, retain, readonly) NSInputStream *inputStream;
@property(nonatomic, assign) id <SKPStreamingJSONParserDelegate> delegate;
@property(nonatomic, retain, readonly) NSError *parserError;

- (id)initWithReadStream:(NSInputStream *)aStream;
- (BOOL)parse;

@end
