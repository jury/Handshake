//
//  NSString+SKPPhoneAdditions.m
//  Handshake
//
//  Created by Kyle on 9/28/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

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
