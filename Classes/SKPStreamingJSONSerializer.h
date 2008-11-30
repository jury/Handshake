//
//  SKPStreamingJSONSerializer.h
//  Handshake
//
//  Created by Ian Baird on 11/17/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//
//  Originally based on TouchJSON by Jonathan Wight.
//

#import <Foundation/Foundation.h>

@class SKPStreamingJSONSerializer;

@protocol SKPStreamingJSONSerializerDelegate <NSObject>

@optional
- (void)streamingJSONSerializerDidComplete:(SKPStreamingJSONSerializer *)streamingJSONSerializer;
- (void)streamingJSONSerializer:(SKPStreamingJSONSerializer *)streamingJSONSerializer didFail:(NSError *)error;

@end

@interface SKPStreamingJSONSerializer : NSObject 
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    NSThread *serializationThread;
    
    id <SKPStreamingJSONSerializerDelegate> delegate;
    
    BOOL isStarted;
    
    id rootObject;
}

@property(nonatomic, assign) id <SKPStreamingJSONSerializerDelegate> delegate;
@property(nonatomic, assign, readonly) CFReadStreamRef readStream;
@property(nonatomic, retain, readonly) id rootObject;

- (id)initWithRootObject:(id)anObject;

- (void)start;
- (void)cancel;

@end
