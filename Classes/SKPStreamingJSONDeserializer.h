//
//  SKPStreamingJSONDeserializer.h
//  Handshake
//
//  Created by Ian Baird on 11/30/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SKPStreamingJSONDeserializer : NSObject 
{
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
}

@property(nonatomic, retain, readonly) NSOutputStream* outputStream;

@end
