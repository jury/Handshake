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
    NSCharacterSet *numericCharSet = [NSCharacterSet characterSetWithCharactersInString:@"1234567890"];
    NSMutableString *stripped = [NSMutableString string];
    
    int i;
    for (i = 0; i < [self length]; ++i)
    {
        unichar theChar = [self characterAtIndex:i];
        if ([numericCharSet characterIsMember:theChar])
        {
            [stripped appendString:[NSString stringWithCharacters:&theChar length:1]];
        }
    }
    
    return [[stripped copy] autorelease];
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
