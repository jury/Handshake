//
//  SKPStreamingJSONDeserializer.m
//  StreamingJSON
//
//  Created by Ian Baird on 12/2/08.
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

#import "SKPStreamingJSONDeserializer.h"
#import "Base64Transcoder.h"




@interface SKPStreamingJSONDeserializer ()

@property(nonatomic, retain) SKPStreamingJSONParser *jsonParser;
@property(nonatomic, retain) NSMutableArray *objectStack;
@property(nonatomic, retain) NSString *lastKey;
@property(nonatomic, retain) NSFileHandle *dataFileHandle;
@property(nonatomic, retain) NSString *dataFileName;

- (void)popObject;
- (void)pushObject:(id)newObject;

@end

@implementation SKPStreamingJSONDeserializer
@synthesize jsonParser, objectStack, lastKey, delegate, dataFileHandle, dataFileName;

+ (NSFileHandle *)createTempFileHandle:(NSString **)outFileName
{
    char fileBuffer[PATH_MAX];
    snprintf(fileBuffer, PATH_MAX, "%sXXXX.tmp", [NSTemporaryDirectory() UTF8String]);
    int fd = mkstemps(fileBuffer, 4);
    
    if (fd < 0)
    {
        return nil;
    }
    
    if (outFileName)
    {
        *outFileName = [[[NSString alloc] initWithBytes:fileBuffer length:strlen(fileBuffer) encoding:NSUTF8StringEncoding] autorelease];
    }
    
    return [[[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES] autorelease];
}

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
    self.dataFileHandle = nil;
    self.dataFileName = nil;
    
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
    id lastObject = [objectStack lastObject];
    if ([objectStack count] == 1)
    {
        [delegate deserializer:self didParse:lastObject];
        [objectStack removeLastObject];
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
    
    if ([value hasPrefix:@"@@b64@@"])
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // Open the temp file if it doesn't exist.
        if (!dataFileHandle)
        {
            self.dataFileName = nil;
            self.dataFileHandle = [[SKPStreamingJSONDeserializer createTempFileHandle:&dataFileName] retain];
            [dataFileName retain];
        }
        
        NSData *dataToDecode = [value dataUsingEncoding:NSUTF8StringEncoding];
        size_t decodedDataLength = EstimateBase64DecodedDataSize([dataToDecode length] - 7);
        NSMutableData *decodedData = [[NSMutableData alloc] initWithLength:decodedDataLength];
        if (!Base64DecodeDataForJSON([dataToDecode bytes] + 7, [dataToDecode length] - 7, [decodedData mutableBytes], &decodedDataLength))
        {
            NSLog(@"Unable to decode buffer!");
            [NSException raise:@"SKPStreamingJSONDeserializerException" format:@"Unable to decode data buffer!"];
        }
        
        [decodedData setLength:decodedDataLength];
        [dataFileHandle writeData:decodedData];
        [decodedData release];
        
        [pool drain];
    }
    else
    {
        [self pushObject:value];
        [self popObject];
    }
    
    
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
    
    id lastObject = [objectStack lastObject];
    
    NSAssert([lastObject isKindOfClass:[NSMutableArray class]], @"deserializer stack is inconsistent!");
    
    if (dataFileHandle)
    {
        // Close the temp file - open a mapped NSData, then unlink the file
        self.dataFileHandle = nil;
        
        // create an URL to the file
        NSURL *tmpFileURL = [[NSURL alloc] initFileURLWithPath:self.dataFileName];
        

        // Replace the last object on the stack with the data
        [lastObject retain];
        [objectStack removeLastObject];
        id parentObject = [objectStack lastObject];
        [objectStack addObject:tmpFileURL];
        
        // check parent (if exists and is dictionary) for replacment
        if (parentObject)
        {
            if ([parentObject isKindOfClass:[NSMutableDictionary class]])
            {
                id lastObjectKey = [[(NSMutableDictionary *)parentObject allKeysForObject:lastObject] lastObject];
                NSAssert(lastObjectKey, @"inconsistent json found!");
                [(NSMutableDictionary *)parentObject setObject:tmpFileURL forKey:lastObjectKey];
            }
            else if ([parentObject isKindOfClass:[NSMutableArray class]])
            {
                [(NSMutableArray *)parentObject replaceObjectAtIndex:[(NSMutableArray*)parentObject indexOfObject:lastObject] withObject:tmpFileURL];
            }
        }
        
        [lastObject release];
        [tmpFileURL release];
    
        self.dataFileName = nil;
    }

    
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
