//
//  HSK_CJSONSerializer.m
//  Handshake
//
//  Created by Ian Baird on 11/17/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//
//  Originally based on TouchJSON by Jonathan Wight.
//

#import "SKPStreamingJSONSerializer.h"
#import "HSK_CFUtilities.h"
#import "Base64Transcoder.h"

#define JSON_BUFFER_SIZE 4096

@interface SKPStreamingJSONSerializer ()

@property(nonatomic, retain) NSOutputStream *outputStream;
@property(nonatomic, retain, readwrite) NSInputStream *inputStream;

@property(nonatomic, retain) NSThread *serializationThread;

@property(nonatomic, retain, readwrite) id rootObject;

- (void)serializeObject:(id)inObject;
- (void)serializeNull:(NSNull *)inNull;
- (void)serializeNumber:(NSNumber *)inNumber;
- (void)serializeString:(NSString *)inString;
- (void)serializeArray:(NSArray *)inArray;
- (void)serializeDictionary:(NSDictionary *)inDictionary;
- (void)serializeData:(NSData *)inData;

@end

@implementation SKPStreamingJSONSerializer

@synthesize inputStream, outputStream, serializationThread, delegate, rootObject;

- (id)initWithRootObject:(id)anObject
{
    if (self = [super init])
    {
        [NSStream createPairWithUNIXSocketPairWithInputStream:&inputStream outputStream:&outputStream];
        
        [inputStream retain];
        [outputStream retain];
        
        self.rootObject = anObject;
    }
    
    return self;
}

- (void)dealloc
{       
    self.inputStream = nil;
    self.outputStream = nil;
    
    [self.serializationThread cancel];
    self.serializationThread = nil;
    
    self.rootObject = nil;
    
    NSLog(@"serializer dealloc'd!");
    
    [super dealloc];
}

- (void)start
{
    NSAssert(!isStarted, @"already started!");
    isStarted = YES;
    self.serializationThread = [[[NSThread alloc] initWithTarget:self selector:@selector(serializeObjectThread:) object:rootObject] autorelease];
    [serializationThread start];
}

- (void)cancel
{
    [serializationThread cancel];
}

- (void)serializeObjectThread:(id)inObject
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSRunLoop *currentLoop = [NSRunLoop currentRunLoop];
    
    [outputStream scheduleInRunLoop:currentLoop forMode:NSRunLoopCommonModes];
    [outputStream open];
    
    BOOL success = NO;
    
    @try
    {
        [self serializeObject:inObject];
        
        success = YES;
    }
    @catch(NSException *exception)
    {
        NSLog(@"ERROR: %@", [exception description]);
    }
    
    NSLog(@"*** closing output stream ***");
    
    [outputStream close];
    [outputStream removeFromRunLoop:currentLoop forMode:NSRunLoopCommonModes];
    
    // Poll until the stream is empty.
    NSStreamStatus inStatus;
    BOOL inDone = NO;
    while (!inDone)
    {
        inStatus = [inputStream streamStatus];
        switch(inStatus)
        {
            case NSStreamStatusAtEnd:
            case NSStreamStatusClosed:
            case NSStreamStatusError:
                inDone = YES;
                break;
            default:
                NSLog(@"*** waiting on stream close, status: %d ***", inStatus);
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, true);
        }
    }
    
    NSLog(@"*** stream empty - thread shutdown started ***");
    
    if (success)
    {
        if ([(NSObject*)delegate respondsToSelector:@selector(streamingJSONSerializerDidComplete:)])
        {
            [delegate streamingJSONSerializerDidComplete:self];
        }
    }
    else
    {
        if ([(NSObject *)delegate respondsToSelector:@selector(streamingJSONSerializer:didFail:)])
        {
            NSString *localizedDescription = [NSString stringWithFormat:@"Cannot serialize data of type '%@'", NSStringFromClass([inObject class])];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:localizedDescription forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"HSK_CJSONSerializer" code:0 userInfo:userInfo];
            
            [delegate streamingJSONSerializer:self didFail:error];
        }
    }
    
    [pool drain];
}

- (void)serializeObject:(id)inObject;
{
    NSAssert(outputStream != NULL, @"outStream must be set!");
    
    if ([inObject isKindOfClass:[NSNull class]])
	{
        [self serializeNull:inObject];
	}
    else if ([inObject isKindOfClass:[NSNumber class]])
	{
        [self serializeNumber:inObject];
	}
    else if ([inObject isKindOfClass:[NSString class]])
	{
        [self serializeString:inObject];
	}
    else if ([inObject isKindOfClass:[NSArray class]])
	{
        [self serializeArray:inObject];
	}
    else if ([inObject isKindOfClass:[NSDictionary class]])
	{
        [self serializeDictionary:inObject];
	}
    else if ([inObject isKindOfClass:[NSData class]])
	{
        [self serializeData:inObject];
	}
    else
	{
        [NSException raise:@"HSK_CJSONSerializer" format:@"Error serializing object with type: %@", NSStringFromClass([inObject class])];
	}
}

- (void)serializeNull:(NSNull *)inNull
{
#pragma unused (inNull)
    NSAssert(outputStream != nil, @"outStream must be set!");
        
    [outputStream writeFully:(const uint8_t *)[@"null" UTF8String] maxLength:[@"null" lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)serializeNumber:(NSNumber *)inNumber
{
    NSAssert(outputStream != nil, @"outStream must be set!");
    
    NSString *theResult = NULL;
    switch (CFNumberGetType((CFNumberRef)inNumber))
	{
        case kCFNumberCharType:
		{
            int theValue = [inNumber intValue];
            if (theValue == 0)
                theResult = @"false";
            else if (theValue == 1)
                theResult = @"true";
            else
                theResult = [inNumber stringValue];
		}
            break;
        case kCFNumberSInt8Type:
        case kCFNumberSInt16Type:
        case kCFNumberSInt32Type:
        case kCFNumberSInt64Type:
        case kCFNumberFloat32Type:
        case kCFNumberFloat64Type:
        case kCFNumberShortType:
        case kCFNumberIntType:
        case kCFNumberLongType:
        case kCFNumberLongLongType:
        case kCFNumberFloatType:
        case kCFNumberDoubleType:
        case kCFNumberCFIndexType:
        default:
            theResult = [inNumber stringValue];
            break;
	}
    
    [outputStream writeFully:(const uint8_t *)[theResult UTF8String] maxLength:[theResult lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)serializeString:(NSString *)inString
{
    NSAssert(outputStream != nil, @"outStream must be set!");
    
    NSMutableString *theMutableCopy = [[inString mutableCopy] autorelease];
    [theMutableCopy replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, [theMutableCopy length])];
    [theMutableCopy replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, [theMutableCopy length])];
    [theMutableCopy replaceOccurrencesOfString:@"/" withString:@"\\/" options:0 range:NSMakeRange(0, [theMutableCopy length])];
    [theMutableCopy replaceOccurrencesOfString:@"\b" withString:@"\\b" options:0 range:NSMakeRange(0, [theMutableCopy length])];
    [theMutableCopy replaceOccurrencesOfString:@"\f" withString:@"\\f" options:0 range:NSMakeRange(0, [theMutableCopy length])];
    [theMutableCopy replaceOccurrencesOfString:@"\r" withString:@"\\r" options:0 range:NSMakeRange(0, [theMutableCopy length])];
    [theMutableCopy replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, [theMutableCopy length])];
    [theMutableCopy replaceOccurrencesOfString:@"\t" withString:@"\\t" options:0 range:NSMakeRange(0, [theMutableCopy length])];
    /*
     case 'u':
     {
     theCharacter = 0;
     
     int theShift;
     for (theShift = 12; theShift >= 0; theShift -= 4)
     {
     int theDigit = HexToInt([self scanCharacter]);
     if (theDigit == -1)
     {
     [self setScanLocation:theScanLocation];
     return(NO);
     }
     theCharacter |= (theDigit << theShift);
     }
     }
     */
    NSString *outString = [NSString stringWithFormat:@"\"%@\"", theMutableCopy];
    [outputStream writeFully:(const uint8_t *)[outString UTF8String] maxLength:[outString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
}



- (void)serializeArray:(NSArray *)inArray
{
    static uint8_t *leftSquareBracket = (uint8_t *)"[";
    static uint8_t *rightSquareBracket = (uint8_t *)"]";
    static uint8_t *comma = (uint8_t *)",";
    
    NSAssert(outputStream != NULL, @"outStream must be set!");
    
    NSEnumerator *theEnumerator = [inArray objectEnumerator];
    id theValue = NULL;
    
    [outputStream writeFully:leftSquareBracket maxLength:1];
    
    while ((theValue = [theEnumerator nextObject]) != NULL)
	{
        if ([[NSThread currentThread] isCancelled])
            return;
        
        [self serializeObject:theValue];
        
        if (theValue != [inArray lastObject])
        {
            [outputStream writeFully:comma maxLength:1];
        }
	}
    
    [outputStream writeFully:rightSquareBracket maxLength:1];
}

- (void)serializeDictionary:(NSDictionary *)inDictionary
{
    static uint8_t *leftCurlyBracket = (uint8_t *)"{";
    static uint8_t *rightCurlyBracket = (uint8_t *)"}";
    static uint8_t *colon = (uint8_t *)":";
    static uint8_t *comma = (uint8_t *)",";
    
    NSAssert(outputStream != NULL, @"outStream must be set!");
        
    NSArray *theKeys = [inDictionary allKeys];
    NSEnumerator *theEnumerator = [theKeys objectEnumerator];
    NSString *theKey = NULL;
    
    [outputStream writeFully:leftCurlyBracket maxLength:1];
    
    while ((theKey = [theEnumerator nextObject]) != NULL)
	{
        if ([[NSThread currentThread] isCancelled])
            return;
        
        id theValue = [inDictionary objectForKey:theKey];
        
        [self serializeString:theKey]; 
        [outputStream writeFully:colon maxLength:1];
        [self serializeObject:theValue];
        if (theKey != [theKeys lastObject])
        {
            [outputStream writeFully:comma maxLength:1];
        }
	}
    
    [outputStream writeFully:rightCurlyBracket maxLength:1];
}

#define DATA_CHUNK_SIZE 4096

- (void)serializeData:(NSData *)inData;
{
    static uint8_t leftSquareBracket = '[';
    static uint8_t rightSquareBracket = ']';
    static uint8_t comma = ',';
    static uint8_t doubleQuote = '"';
    NSString *header = [NSString stringWithFormat:@"@@b64@@"];
    
    
    
    // Start the array
    [outputStream writeFully:&leftSquareBracket maxLength:1];
    
    UInt8 *rawDataPtr = (UInt8 *)[inData bytes];
    UInt8 *rawDataEndPtr = rawDataPtr + [inData length];
    
    NSUInteger encodedDataSize = sizeof(UInt8) * EstimateBase64EncodedDataSize(DATA_CHUNK_SIZE); 
    UInt8 *encodedData = malloc(encodedDataSize);
    
    while (1)
    {
        if (rawDataPtr >= rawDataEndPtr)
        {
            break;
        }
        
        size_t inputDataSize = (rawDataEndPtr - rawDataPtr) < DATA_CHUNK_SIZE ? (rawDataEndPtr - rawDataPtr) : DATA_CHUNK_SIZE;
        size_t outputDataSize = EstimateBase64EncodedDataSize(inputDataSize);
        memset(encodedData, 0, encodedDataSize);
        
        
        Base64EncodeDataForJSON(rawDataPtr, inputDataSize, (char *)encodedData, &outputDataSize);
        
        [outputStream writeFully:&doubleQuote maxLength:1];
        // Add a proprietary header
        [outputStream writeFully:(const uint8_t *)[header UTF8String] maxLength:[header lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
        [outputStream writeFully:encodedData maxLength:outputDataSize];
        [outputStream writeFully:&doubleQuote maxLength:1];
        
        rawDataPtr += DATA_CHUNK_SIZE;
        
        if (rawDataPtr < rawDataEndPtr)
        {
            [outputStream writeFully:&comma maxLength:1];
        }
        
    }
    
    free(encodedData);
    
    [outputStream writeFully:&rightSquareBracket maxLength:1];
}



@end
