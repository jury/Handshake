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

@property(nonatomic, assign) CFWriteStreamRef writeStream;
@property(nonatomic, assign, readwrite) CFReadStreamRef readStream;

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

@synthesize readStream, writeStream, serializationThread, delegate, rootObject;

- (id)initWithRootObject:(id)anObject
{
    if (self = [super init])
    {
        CFStreamCreatePairWithUNIXSocketPair(NULL, &readStream, &writeStream);
        
        self.rootObject = anObject;
    }
    
    return self;
}

- (void)dealloc
{       
    if (readStream)
    {
        CFRelease(readStream);
        readStream = NULL;
    }
    
    if (writeStream)
    {
        CFRelease(writeStream);
        writeStream = NULL;
    }
    
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
    
    CFRunLoopRef currentLoop = CFRunLoopGetCurrent();
    
    CFWriteStreamScheduleWithRunLoop(writeStream, currentLoop, kCFRunLoopCommonModes);
    CFWriteStreamOpen(writeStream);
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
    CFWriteStreamClose(writeStream);
    CFWriteStreamUnscheduleFromRunLoop(writeStream, currentLoop, kCFRunLoopCommonModes);
    
    // Poll until the stream is empty.
    CFStreamStatus inStatus;
    BOOL inDone = NO;
    while (!inDone)
    {
        inStatus = CFReadStreamGetStatus(readStream);
        switch(inStatus)
        {
            case kCFStreamStatusAtEnd:
            case kCFStreamStatusClosed:
            case kCFStreamStatusError:
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
    NSAssert(writeStream != NULL, @"outStream must be set!");
    
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
    NSAssert(writeStream != NULL, @"outStream must be set!");
        
    CFWriteStreamWriteFully(writeStream, (const uint8_t *)[@"null" UTF8String], [@"null" lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
}

- (void)serializeNumber:(NSNumber *)inNumber
{
    NSAssert(writeStream != NULL, @"outStream must be set!");
    
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
    
    CFWriteStreamWriteFully(writeStream, (const uint8_t *)[theResult UTF8String], [theResult lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
}

- (void)serializeString:(NSString *)inString
{
    NSAssert(writeStream != NULL, @"outStream must be set!");
    
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
    CFWriteStreamWriteFully(writeStream, (const uint8_t *)[outString UTF8String], [outString lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
}



- (void)serializeArray:(NSArray *)inArray
{
    static uint8_t *leftSquareBracket = (uint8_t *)"[";
    static uint8_t *rightSquareBracket = (uint8_t *)"]";
    static uint8_t *comma = (uint8_t *)",";
    
    NSAssert(writeStream != NULL, @"outStream must be set!");
    
    NSEnumerator *theEnumerator = [inArray objectEnumerator];
    id theValue = NULL;
    
    //[outputStream write:leftSquareBracket maxLength:1];
    CFWriteStreamWriteFully(writeStream, leftSquareBracket, 1);
    
    while ((theValue = [theEnumerator nextObject]) != NULL)
	{
        if ([[NSThread currentThread] isCancelled])
            return;
        
        [self serializeObject:theValue];
        
        if (theValue != [inArray lastObject])
        {
            //[outputStream write:comma maxLength:1];
            CFWriteStreamWriteFully(writeStream, comma, 1);
        }
	}
    
    //[outputStream write:rightSquareBracket maxLength:1];
    CFWriteStreamWriteFully(writeStream, rightSquareBracket, 1);
}

- (void)serializeDictionary:(NSDictionary *)inDictionary
{
    static uint8_t *leftCurlyBracket = (uint8_t *)"{";
    static uint8_t *rightCurlyBracket = (uint8_t *)"}";
    static uint8_t *colon = (uint8_t *)":";
    static uint8_t *comma = (uint8_t *)",";
    
    NSAssert(writeStream != NULL, @"outStream must be set!");
        
    NSArray *theKeys = [inDictionary allKeys];
    NSEnumerator *theEnumerator = [theKeys objectEnumerator];
    NSString *theKey = NULL;
    
    //[outputStream write:leftCurlyBracket maxLength:1];
    CFWriteStreamWriteFully(writeStream, leftCurlyBracket, 1);
    
    while ((theKey = [theEnumerator nextObject]) != NULL)
	{
        if ([[NSThread currentThread] isCancelled])
            return;
        
        id theValue = [inDictionary objectForKey:theKey];
        
        [self serializeString:theKey]; 
        //[outputStream write:colon maxLength:1];
        CFWriteStreamWriteFully(writeStream, colon, 1);
        [self serializeObject:theValue];
        if (theKey != [theKeys lastObject])
        {
            //[outputStream write:comma maxLength:1];
            CFWriteStreamWriteFully(writeStream, comma, 1);
        }
	}
    
    //[outputStream write:rightCurlyBracket maxLength:1];
    CFWriteStreamWriteFully(writeStream, rightCurlyBracket, 1);
}

#define DATA_CHUNK_SIZE 256

- (void)serializeData:(NSData *)inData;
{
    static uint8_t leftSquareBracket = '[';
    static uint8_t rightSquareBracket = ']';
    static uint8_t comma = ',';
    static uint8_t doubleQuote = '"';
    NSString *header = [NSString stringWithFormat:@"@@b64@@"];
    
    
    
    // Start the array
    CFWriteStreamWriteFully(writeStream, &leftSquareBracket, 1);
    
    // TODO: up this buffer size
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
        
        CFWriteStreamWriteFully(writeStream, &doubleQuote, 1);
        // Add a proprietary header
        CFWriteStreamWriteFully(writeStream, (const uint8_t *)[header UTF8String], [header lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        CFWriteStreamWriteFully(writeStream, encodedData, outputDataSize);
        CFWriteStreamWriteFully(writeStream, &doubleQuote, 1);
        
        rawDataPtr += DATA_CHUNK_SIZE;
        
        if (rawDataPtr < rawDataEndPtr)
        {
            CFWriteStreamWriteFully(writeStream, &comma, 1);
        }
        
    }
    
    free(encodedData);
    
    CFWriteStreamWriteFully(writeStream, &rightSquareBracket, 1);
    
    // Stream-based read of data - deprecated.
    /*
    CFReadStreamRef dataInputStream = CFReadStreamCreateWithBytesNoCopy(NULL, (const UInt8 *)[inData bytes], [inData length], kCFAllocatorNull);
    CFReadStreamScheduleWithRunLoop(dataInputStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFReadStreamOpen(dataInputStream);
    
    Base64EncodeFromStreamToStreamForJSON(dataInputStream, [inData length], writeStream, NO);
    
    CFReadStreamClose(dataInputStream);
    CFReadStreamUnscheduleFromRunLoop(dataInputStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    CFRelease(dataInputStream);
    */
    
    
}



@end
