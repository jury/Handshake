//
//  HSK_CJSONDeserializer.m
//  TouchJSON
//
//  Created by Jonathan Wight on 12/15/2005.
//  Copyright (c) 2005 Jonathan Wight
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "HSK_CJSONDeserializer.h"

#import "HSK_CJSONScanner.h"
#import "HSK_CDataScanner.h"

NSString *const kHSK_JSONDeserializerErrorDomain  = @"HSK_CJSONDeserializerErrorDomain";

@implementation HSK_CJSONDeserializer

+ (id)deserializer
{
return([[[self alloc] init] autorelease]);
}

- (id)deserializeAsDictionary:(NSData *)inData error:(NSError **)outError;
{
if (inData == NULL || [inData length] == 0)
	{
	if (outError)
		*outError = [NSError errorWithDomain:kHSK_JSONDeserializerErrorDomain code:-1 userInfo:NULL];

	return(NULL);
	}
HSK_CJSONScanner *theScanner = [HSK_CJSONScanner scannerWithData:inData];
NSDictionary *theDictionary = NULL;
if ([theScanner scanJSONDictionary:&theDictionary error:outError] == YES)
	return(theDictionary);
else
	return(NULL);
}

@end

#pragma mark -

@implementation HSK_CJSONDeserializer (HSK_CJSONDeserializer_Deprecated)

- (id)deserialize:(NSData *)inData error:(NSError **)outError
{
if (inData == NULL || [inData length] == 0)
	{
	if (outError)
		*outError = [NSError errorWithDomain:kHSK_JSONDeserializerErrorDomain code:-1 userInfo:NULL];

	return(NULL);
	}
HSK_CJSONScanner *theScanner = [HSK_CJSONScanner scannerWithData:inData];
id theObject = NULL;
if ([theScanner scanJSONObject:&theObject error:outError] == YES)
	return(theObject);
else
	return(NULL);
}

@end
