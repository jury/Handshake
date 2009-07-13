//
//  SKPStreamingJSONParser.h
//  StreamingJSON
//
//  Created by Ian Baird on 11/29/08.
//  Copyright (c) 2009, Skorpiostech, Inc.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//      * Neither the name of the Skorpiostech, Inc. nor the
//        names of its contributors may be used to endorse or promote products
//        derived from this software without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY SKORPIOSTECH, INC. ''AS IS'' AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL SKORPIOSTECH, INC. BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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

- (void)parserDidComplete:(SKPStreamingJSONParser *)sender;
- (void)parser:(SKPStreamingJSONParser *)sender didFail:(NSError *)error;

@end

@interface SKPStreamingJSONParser : NSObject 
{
    yajl_handle yajlHandle;
    
    NSInputStream *inputStream;
    
    BOOL isFinished;
    BOOL isParsing;
    BOOL isAsync;
    
    id <SKPStreamingJSONParserDelegate> delegate;
    
    NSError *parserError;
}

@property(nonatomic, retain, readonly) NSInputStream *inputStream;
@property(nonatomic, assign) id <SKPStreamingJSONParserDelegate> delegate;
@property(nonatomic, retain, readonly) NSError *parserError;

- (id)initWithInputStream:(NSInputStream *)aStream;
- (BOOL)parse;
- (void)startAsynchronousParsing;
- (void)stopAsynchronousParsing;

@end
