//
//  SKPInflateStreamConnector.h
//  StreamingJSON
//
//  Created by Ian Baird on 12/1/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SKPInputStreamConnector.h"

#include <zlib.h>

@interface SKPInflateStreamConnector : SKPInputStreamConnector 
{
    z_stream strm;
}

@end
