//
//  SKPStreamingJSONDeserializer.m
//  Handshake
//
//  Created by Ian Baird on 11/30/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "SKPStreamingJSONDeserializer.h"

#import "HSK_CFUtilities.h"

@interface SKPStreamingJSONDeserializer ()

@property(nonatomic, retain) NSInputStream *inputStream;
@property(nonatomic, retain, readwrite) NSOutputStream *outputStream;

@end

@implementation SKPStreamingJSONDeserializer

@synthesize inputStream, outputStream;

- (id)init
{
    if (self = [super init])
    {
        [NSStream createPairWithUNIXSocketPairWithInputStream:&inputStream outputStream:&outputStream];
        
        [inputStream retain];
        [outputStream retain];
    }
    
    return self;
}

- (void)dealloc
{
    [inputStream close];
    [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.inputStream = nil;
    self.outputStream = nil;
    
    [super dealloc];
}

@end
