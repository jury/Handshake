//
//  NSString+SKPPhoneAdditions.m
//  Handshake
//
//  Created by Kyle on 9/28/08.
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
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.//

#import "NSString+SKPPhoneAdditions.h"


@implementation NSString (SKPPhoneAdditions)

-(NSString *)numericOnly
{
    static NSCharacterSet *numericCharSet = nil;
    
    if (!numericCharSet)
    {
        numericCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890"] retain];
    }
    
    int len = [self length];
    unichar *srcCharBuf = calloc([self length] + 1, sizeof(unichar));
    [self getCharacters:srcCharBuf];
    
    unichar *dstCharBuf = calloc([self length] + 1, sizeof(unichar));
    NSUInteger dstCharBufInd = 0;
    
    int i;
    for (i = 0; i < len; ++i)
    {
        if ([numericCharSet characterIsMember:srcCharBuf[i]])
        {
            dstCharBuf[dstCharBufInd++] = srcCharBuf[i];
        }
    }
    
    NSString *stripped = [NSString stringWithCharacters:dstCharBuf length:dstCharBufInd];
    
    free(srcCharBuf);
    free(dstCharBuf);
    
    return stripped;
}

- (NSString *)formattedUSPhoneNumber
{
    NSString *rawNumber = [self numericOnly];
    NSMutableString *formattedNumber = [NSMutableString string];
    
    int i;
    for (i = 0; (i < [rawNumber length] && (i < 10)); ++i)
    {
        unichar theChar = [rawNumber characterAtIndex:i];
        
        if ( (i == 3) || (i == 6) )
        {
            [formattedNumber appendString:@"-"];
        }
        
        [formattedNumber appendString:[NSString stringWithCharacters:&theChar length:1]];
    }
    
    return [[formattedNumber copy] autorelease];
}

@end
