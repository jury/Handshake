//
//  SKPGzipStreamConnector.h
//  StreamingJSON
//
//  Created by Ian Baird on 11/30/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SKPInputStreamConnector.h"

#include <zlib.h>

@interface SKPDeflateStreamConnector : SKPInputStreamConnector 
{
    z_stream strm;    
}

@end
