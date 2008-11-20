//
//  HSKABMethods.m
//  Handshake
//
//  Created by Kyle on 11/2/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKABMethods.h"
#import "Beacon.h"
#import "NSData+Base64Additions.h"
#import "HSKBeacons.h"
#import "HSKMessageDefines.h"

#pragma mark -
#pragma mark ABHelper methods

static inline CFTypeRef ABRecordCopyValueAndAutorelease(ABRecordRef record, ABPropertyID property)
{
    return [(id) ABRecordCopyValue(record, property) autorelease];
}

static inline CFTypeRef ABMultiValueCopyValueAtIndexAndAutorelease(ABMultiValueRef multiValue, CFIndex index)
{
    return [(id) ABMultiValueCopyValueAtIndex(multiValue, index) autorelease];
}

@implementation HSKABMethods

static HSKABMethods *_instance = nil;

+ (id)sharedInstance
{
    if (!_instance)
    {
        _instance = [[HSKABMethods alloc] init];
        
	}
    
    return _instance;
}

//This function will format and return a valid vCard
-(NSString *)formatForVcard:(NSDictionary *)vCardDictionary
{
	//vCards feel the need
	int itemRunningCount = 1;
	
	//dont forget to remove first line return newb!
	NSString *formattedVcard = @"BEGIN:VCARD\nVERSION:3.0\n";
	
	//name formatters for both "N" and "FN"
	if([vCardDictionary objectForKey: @"FirstName"] != nil || [vCardDictionary objectForKey: @"LastName"] != nil || [vCardDictionary objectForKey: @"MiddleName"] != nil)
	{
		//we have a name lets prefix it
		formattedVcard = [formattedVcard stringByAppendingString:@"N:"];
		
		if([vCardDictionary objectForKey: @"LastName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@;", [vCardDictionary objectForKey: @"LastName"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
		if([vCardDictionary objectForKey: @"FirstName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@;", [vCardDictionary objectForKey: @"FirstName"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
		if([vCardDictionary objectForKey: @"MiddleName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@;", [vCardDictionary objectForKey: @"MiddleName"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
		if([vCardDictionary objectForKey: @"Prefix"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@;", [vCardDictionary objectForKey: @"Prefix"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
		if([vCardDictionary objectForKey: @"Suffix"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@\n", [vCardDictionary objectForKey: @"Suffix"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
		
		
		//formatted name header
		formattedVcard = [formattedVcard stringByAppendingString:@"FN:"];
		
		if([vCardDictionary objectForKey: @"Prefix"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@ ", [vCardDictionary objectForKey: @"Prefix"]]];
		if([vCardDictionary objectForKey: @"FirstName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@ ", [vCardDictionary objectForKey: @"FirstName"]]];
		if([vCardDictionary objectForKey: @"MiddleName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@ ", [vCardDictionary objectForKey: @"MiddleName"]]];
		if([vCardDictionary objectForKey: @"LastName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@ ", [vCardDictionary objectForKey: @"LastName"]]];
		if([vCardDictionary objectForKey: @"Suffix"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@\n", [vCardDictionary objectForKey: @"Suffix"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
	}
	
	//nickname
	if([vCardDictionary objectForKey: @"Nickname"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"NICKNAME:%@\n", [vCardDictionary objectForKey: @"Nickname"]]];
	
	//maiden name -- We be fucked for now, will look at later
	
	//ORG
	if([vCardDictionary objectForKey: @"OrgName"] != nil || [vCardDictionary objectForKey: @"Department"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString: @"ORG:"];
		
		if([vCardDictionary objectForKey: @"OrgName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"%@;", [vCardDictionary objectForKey: @"OrgName"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([vCardDictionary objectForKey: @"Department"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"%@", [vCardDictionary objectForKey: @"Department"]]];
		
		formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
	}
	
	//job title
	if([vCardDictionary objectForKey: @"JobTitle"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"TITLE:%@\n", [vCardDictionary objectForKey: @"JobTitle"]]];
	
	//vCards do not support user images - gonna have to forfit them
	
	//EMAIL Handlers
	if([vCardDictionary objectForKey: @"*EMAIL_$!<Home>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"EMAIL;type=INTERNET;type=HOME:%@\n", [vCardDictionary objectForKey: @"*EMAIL_$!<Home>!$_"]]];
	if([vCardDictionary objectForKey: @"*EMAIL_$!<Work>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"EMAIL;type=INTERNET;type=WORK:%@\n", [vCardDictionary objectForKey: @"*EMAIL_$!<Work>!$_"]]];
	if([vCardDictionary objectForKey: @"*EMAIL_$!<Other>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.EMAIL;type=INTERNET:%@\nitem%i.X-ABLabel:_$!<Other>!$_\n", itemRunningCount, [vCardDictionary objectForKey: @"*EMAIL_$!<Other>!$_"], itemRunningCount]];
		itemRunningCount++;
	}
	
	//Custom Email Handlers
	for(int x = 0; x < [[vCardDictionary allKeys] count]; x++)
	{			
		if([[[vCardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[vCardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*EMAIL"])
		{
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.EMAIL;type=INTERNET:%@\nitem%i.X-ABLabel:%@\n", itemRunningCount,  [vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]], itemRunningCount, [[[vCardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*EMAIL" withString: @""]]];
			itemRunningCount++;
		}
	}
	
	if([vCardDictionary objectForKey: @"*PHONE_$!<Home>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=HOME:%@\n", [vCardDictionary objectForKey: @"*PHONE_$!<Home>!$_"]]];
	if([vCardDictionary objectForKey: @"*PHONE_$!<Work>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=WORK:%@\n", [vCardDictionary objectForKey: @"*PHONE_$!<Work>!$_"]]];
	if([vCardDictionary objectForKey: @"*PHONE_$!<Mobile>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=CELL:%@\n", [vCardDictionary objectForKey: @"*PHONE_$!<Mobile>!$_"]]];
	if([vCardDictionary objectForKey: @"*PHONE_$!<Main>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=MAIN:%@\n", [vCardDictionary objectForKey: @"*PHONE_$!<Main>!$_"]]];
	if([vCardDictionary objectForKey: @"*PHONE_$!<WorkFAX>!$_"] != nil)		
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=WORK;type=FAX:%@\n", [vCardDictionary objectForKey: @"*PHONE_$!<WorkFAX>!$_"]]];
	if([vCardDictionary objectForKey: @"*PHONE_$!<Pager>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=PAGER:%@\n", [vCardDictionary objectForKey: @"*PHONE_$!<Pager>!$_"]]];
	if([vCardDictionary objectForKey: @"*PHONE_$!<HomeFAX>!$_"] != nil)		
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=WORK;type=FAX:%@\n", [vCardDictionary objectForKey: @"*PHONE_$!<HomeFAX>!$_"]]];
	if([vCardDictionary objectForKey: @"*PHONE_$!<Other>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.TEL:%@\nitem%i.X-ABLabel:_$!<Other>!$_\n", itemRunningCount, [vCardDictionary objectForKey: @"*PHONE_$!<Other>!$_"], itemRunningCount]];
		itemRunningCount++;
	}
	
	for(int x = 0; x < [[vCardDictionary allKeys] count]; x++)
	{
		if([[[vCardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[vCardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*PHONE"])
		{
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.TEL:%@\nitem%i.X-ABLabel:%@\n", itemRunningCount, [vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]], itemRunningCount, [[[vCardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*PHONE" withString: @""]]];
			itemRunningCount++;
		}
	}
	
	//address handler HOME
	if([vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.ADR;type=HOME:;;", itemRunningCount]];
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"Street"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[[vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_" ] objectForKey:@"Street"] stringByReplacingOccurrencesOfString: @"\n" withString: @" "]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"City"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"City"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"State"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"State"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"ZIP"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"ZIP"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";\n"];
		
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"CountryCode"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABADR:", itemRunningCount]];
			formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"CountryCode"]];
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:Home\n", itemRunningCount]];
		itemRunningCount++;
	}
	
	//address handler Work
	if([vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.ADR;type=WORK:;;", itemRunningCount]];
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"Street"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[[vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_" ] objectForKey:@"Street"] stringByReplacingOccurrencesOfString: @"\n" withString: @" "]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"City"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"City"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"State"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"State"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"ZIP"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"ZIP"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";\n"];
		
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"CountryCode"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABADR:", itemRunningCount]];
			formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"CountryCode"]];
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:Work\n", itemRunningCount]];
		itemRunningCount++;
	}
	
	//address handler Other
	if([vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.ADR;type=HOME:;;", itemRunningCount]]; //all custom flags will be defined as home, we catch these with the label gaurd
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"Street"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[[vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_" ] objectForKey:@"Street"] stringByReplacingOccurrencesOfString: @"\n" withString: @" "]];
			
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"City"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"City"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"State"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"State"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"ZIP"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"ZIP"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";\n"];
		
		
		if([[vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"CountryCode"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABADR:", itemRunningCount]];
			formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"CountryCode"]];
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
		}
		
		
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:Other\n", itemRunningCount]];
		itemRunningCount++;
	}
	
	
	//Address Handle Custom
	for(int x = 0; x < [[vCardDictionary allKeys] count]; x++)
	{			
		if([[[vCardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[vCardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*ADDRESS"])
		{
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.ADR;type=HOME:;;", itemRunningCount]]; //all custom flags will be defined as home, we catch these with the label gaurd
			
			if([[vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]] objectForKey:@"Street"] != nil)
			{
				formattedVcard = [formattedVcard stringByAppendingString: [[[vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]] objectForKey:@"Street"] stringByReplacingOccurrencesOfString: @"\n" withString: @" "]];
			}
			
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
			
			if([[vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]] objectForKey:@"City"] != nil)
			{
				formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]] objectForKey:@"City"]];
			}
			
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
			
			if([[vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]] objectForKey:@"State"] != nil)
			{
				formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]] objectForKey:@"State"]];
			}
			
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
			
			if([[vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]] objectForKey:@"ZIP"] != nil)
			{
				formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]] objectForKey:@"ZIP"]];
			}
			
			formattedVcard = [formattedVcard stringByAppendingString: @";\n"];
			
			
			if([[vCardDictionary objectForKey:[[vCardDictionary allKeys] objectAtIndex: x]] objectForKey:@"CountryCode"] != nil)
			{
				formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABADR:", itemRunningCount]];
				formattedVcard = [formattedVcard stringByAppendingString: [[vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]] objectForKey:@"CountryCode"]];
				formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
			}
			
			
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:%@\n", itemRunningCount, [[[vCardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*ADDRESS" withString: @""]]];
			itemRunningCount++;
		}
	}
	
	
	//URL Handlers 
	if([vCardDictionary objectForKey: @"*URL_$!<Home>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"URL;type=HOME:%@\n", [vCardDictionary objectForKey: @"*URL_$!<Home>!$_"]]];
	if([vCardDictionary objectForKey: @"*URL_$!<Work>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"URL;type=WORK:%@\n", [vCardDictionary objectForKey: @"*URL_$!<Work>!$_"]]];
	if([vCardDictionary objectForKey: @"*URL_$!<Other>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.URL:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*URL_$!<Other>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Other>!$_\n", itemRunningCount]];
		itemRunningCount++;
	}
	if([vCardDictionary objectForKey: @"*URL_$!<HomePage>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.URL:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*URL_$!<HomePage>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<HomePage>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	
	for(int x = 0; x < [[vCardDictionary allKeys] count]; x++)
	{			
		if([[[vCardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[vCardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*URL"])
		{
			formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.URL:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*URL_$!<HomePage>!$_"]]];
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:%@\n", itemRunningCount, [[[vCardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*URL" withString: @""]]]; 
			itemRunningCount++;
		}
	}
	
	//RELATED HANDLERS
	if([vCardDictionary objectForKey: @"*RELATED_$!<Mother>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*RELATED_$!<Mother>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Mother>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([vCardDictionary objectForKey: @"*RELATED_$!<Father>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*RELATED_$!<Father>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Father>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([vCardDictionary objectForKey: @"*RELATED_$!<Parent>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*RELATED_$!<Parent>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Parent>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([vCardDictionary objectForKey: @"*RELATED_$!<Sister>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*RELATED_$!<Sister>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Sister>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([vCardDictionary objectForKey: @"*RELATED_$!<Brother>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*RELATED_$!<Brother>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Brother>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([vCardDictionary objectForKey: @"*RELATED_$!<Child>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*RELATED_$!<Child>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Child>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([vCardDictionary objectForKey: @"*RELATED_$!<Friend>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*RELATED_$!<Friend>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Friend>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([vCardDictionary objectForKey: @"*RELATED_$!<Partner>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*RELATED_$!<Partner>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Partner>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([vCardDictionary objectForKey: @"*RELATED_$!<Manager>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*RELATED_$!<Manager>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Manager>!$_\n", itemRunningCount]]; 
		itemRunningCount++;	
	}
	if([vCardDictionary objectForKey: @"*RELATED_$!<Assistant>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*RELATED_$!<Assistant>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Assistant>!$_\n", itemRunningCount]]; 
		itemRunningCount++;	
		
	}
	if([vCardDictionary objectForKey: @"*RELATED_$!<Spouse>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [vCardDictionary objectForKey: @"*RELATED_$!<Spouse>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Spouse>!$_\n", itemRunningCount]]; 
		itemRunningCount++;	
		
	}
	
	for(int x = 0; x < [[vCardDictionary allKeys] count]; x++)
	{		
		if([[[vCardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*IM"])
		{
			formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-%@;type=pref:%@\n", itemRunningCount, [[vCardDictionary objectForKey:[[vCardDictionary allKeys] objectAtIndex: x]] objectForKey: @"service"], [[vCardDictionary objectForKey:[[vCardDictionary allKeys] objectAtIndex: x]] objectForKey: @"username"]]];
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:%@\n", itemRunningCount, [[[vCardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*IM" withString: @""]]]; 
			itemRunningCount++;
		}
	}
	
	//end tag for vCard
	return [formattedVcard stringByAppendingString:@"END:VCARD"];
}

- (ABRecordRef)recievedVCard: (NSDictionary *)vCardDictionary fromPeer:(NSString *)lastPeerHandle;
{
	[[Beacon shared] startSubBeaconWithName:kHSKBeaconCardReceivedEvent timeSession:NO];
	
	BOOL specialData = FALSE;
	ABRecordRef newPerson = nil;
	
	NSError *error = nil;
	
	if(!vCardDictionary || error)
	{
		NSLog(@"%@", [error localizedDescription]);
	}
	else
	{		
		CFErrorRef *ABError = NULL;
		newPerson = ABPersonCreate();
		
		//ADDRESS HANDLERS
		ABMutableMultiValueRef addressMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(addressMultiValue, [vCardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"], kABHomeLabel, NULL);
		if([vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(addressMultiValue, [vCardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"], kABWorkLabel, NULL);
		if([vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(addressMultiValue, [vCardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"], kABOtherLabel, NULL);
		
		
		for(int x = 0; x < [[vCardDictionary allKeys] count]; x++)
		{			
			if([[[vCardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[vCardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*ADDRESS"])
			{
				ABMultiValueAddValueAndLabel(addressMultiValue, [vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[vCardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*ADDRESS" withString: @""] , NULL);	
			}
		}
		
		
		ABRecordSetValue(newPerson, kABPersonAddressProperty, addressMultiValue, ABError);
        if (addressMultiValue) CFRelease(addressMultiValue);
		
		//IM HANDLERS
		ABMutableMultiValueRef IMMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([vCardDictionary objectForKey: @"*IM_$!<Home>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(IMMultiValue, [vCardDictionary objectForKey: @"*IM_$!<Home>!$_"], kABHomeLabel, NULL);
			specialData = TRUE;
		}
		if([vCardDictionary objectForKey: @"*IM_$!<Work>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(IMMultiValue, [vCardDictionary objectForKey: @"*IM_$!<Work>!$_"], kABWorkLabel, NULL);
			specialData = TRUE;
		}
		if([vCardDictionary objectForKey: @"*IM_$!<Other>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(IMMultiValue, [vCardDictionary objectForKey: @"*IM_$!<Other>!$_"], kABOtherLabel, NULL);
			specialData = TRUE;
		}
		
		
		for(int x = 0; x < [[vCardDictionary allKeys] count]; x++)
		{			
			if([[[vCardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[vCardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*IM"])
			{
				ABMultiValueAddValueAndLabel(IMMultiValue, [vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[vCardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*IM" withString: @""] , NULL);	
				specialData = TRUE;
			}
		}
		
		
		ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, IMMultiValue, ABError);
        if (IMMultiValue) CFRelease(IMMultiValue);
		
		//EMAIL handlers
		ABMutableMultiValueRef emailMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([vCardDictionary objectForKey: @"*EMAIL_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(emailMultiValue, [vCardDictionary objectForKey: @"*EMAIL_$!<Home>!$_"], kABHomeLabel, NULL);
		if([vCardDictionary objectForKey: @"*EMAIL_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(emailMultiValue, [vCardDictionary objectForKey: @"*EMAIL_$!<Work>!$_"], kABWorkLabel, NULL);
		if([vCardDictionary objectForKey: @"*EMAIL_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(emailMultiValue, [vCardDictionary objectForKey: @"*EMAIL_$!<Other>!$_"], kABOtherLabel, NULL);
		
		for(int x = 0; x < [[vCardDictionary allKeys] count]; x++)
		{			
			if([[[vCardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[vCardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*EMAIL"])
			{
				ABMultiValueAddValueAndLabel(emailMultiValue, [vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[vCardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*EMAIL" withString: @""] , NULL);	
			}
		}
		
		ABRecordSetValue(newPerson, kABPersonEmailProperty, emailMultiValue, ABError);
        if (emailMultiValue) CFRelease(emailMultiValue);
		
		//RELATED HANDLERS
		ABMutableMultiValueRef relatedMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([vCardDictionary objectForKey: @"*RELATED_$!<Mother>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [vCardDictionary objectForKey: @"*RELATED_$!<Mother>!$_"], kABPersonMotherLabel, NULL);
			specialData = TRUE;
		}
		if([vCardDictionary objectForKey: @"*RELATED_$!<Father>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [vCardDictionary objectForKey: @"*RELATED_$!<Father>!$_"], kABPersonFatherLabel, NULL);
			specialData = TRUE;
		}
		if([vCardDictionary objectForKey: @"*RELATED_$!<Parent>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [vCardDictionary objectForKey: @"*RELATED_$!<Parent>!$_"], kABPersonParentLabel, NULL);
			specialData = TRUE;
		}
		if([vCardDictionary objectForKey: @"*RELATED_$!<Sister>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [vCardDictionary objectForKey: @"*RELATED_$!<Sister>!$_"], kABPersonSisterLabel, NULL);
			specialData = TRUE;
		}
		if([vCardDictionary objectForKey: @"*RELATED_$!<Brother>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [vCardDictionary objectForKey: @"*RELATED_$!<Brother>!$_"], kABPersonBrotherLabel, NULL);
			specialData = TRUE;
		}
		if([vCardDictionary objectForKey: @"*RELATED_$!<Child>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [vCardDictionary objectForKey: @"*RELATED_$!<Child>!$_"], kABPersonChildLabel, NULL);
			specialData = TRUE;
		}
		if([vCardDictionary objectForKey: @"*RELATED_$!<Friend>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [vCardDictionary objectForKey: @"*RELATED_$!<Friend>!$_"], kABPersonFriendLabel, NULL);
			specialData = TRUE;
		}
		if([vCardDictionary objectForKey: @"*RELATED_$!<Partner>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [vCardDictionary objectForKey: @"*RELATED_$!<Partner>!$_"], kABPersonPartnerLabel, NULL);
			specialData = TRUE;
		}
		if([vCardDictionary objectForKey: @"*RELATED_$!<Manager>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [vCardDictionary objectForKey: @"*RELATED_$!<Manager>!$_"], kABPersonManagerLabel, NULL);
			specialData = TRUE;
		}
		if([vCardDictionary objectForKey: @"*RELATED_$!<Assistant>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [vCardDictionary objectForKey: @"*RELATED_$!<Assistant>!$_"], kABPersonAssistantLabel, NULL);
			specialData = TRUE;
		}
		if([vCardDictionary objectForKey: @"*RELATED_$!<Spouse>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [vCardDictionary objectForKey: @"*RELATED_$!<Spouse>!$_"], kABPersonSpouseLabel, NULL);
			specialData = TRUE;
		}
		
		
		for(int x = 0; x < [[vCardDictionary allKeys] count]; x++)
		{			
			if([[[vCardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[vCardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*RELATED"])
			{
				ABMultiValueAddValueAndLabel(relatedMultiValue, [vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[vCardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*RELATED" withString: @""] , NULL);	
				specialData = TRUE;
			}
		}
		
		
		ABRecordSetValue(newPerson, kABPersonRelatedNamesProperty, relatedMultiValue, ABError);
        if (relatedMultiValue) CFRelease(relatedMultiValue);
		
		//PHONE HANDLERS
		ABMutableMultiValueRef phoneMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([vCardDictionary objectForKey: @"*PHONE_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [vCardDictionary objectForKey: @"*PHONE_$!<Home>!$_"], kABHomeLabel, NULL);
		if([vCardDictionary objectForKey: @"*PHONE_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [vCardDictionary objectForKey: @"*PHONE_$!<Work>!$_"], kABWorkLabel, NULL);
		if([vCardDictionary objectForKey: @"*PHONE_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [vCardDictionary objectForKey: @"*PHONE_$!<Other>!$_"], kABOtherLabel, NULL);
		if([vCardDictionary objectForKey: @"*PHONE_$!<Mobile>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [vCardDictionary objectForKey: @"*PHONE_$!<Mobile>!$_"], kABPersonPhoneMobileLabel, NULL);
		if([vCardDictionary objectForKey: @"*PHONE_$!<Main>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [vCardDictionary objectForKey: @"*PHONE_$!<Main>!$_"], kABPersonPhoneMainLabel, NULL);
		if([vCardDictionary objectForKey: @"*PHONE_$!<WorkFAX>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [vCardDictionary objectForKey: @"*PHONE_$!<WorkFAX>!$_"], kABPersonPhoneWorkFAXLabel, NULL);
		if([vCardDictionary objectForKey: @"*PHONE_$!<Pager>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [vCardDictionary objectForKey: @"*PHONE_$!<Pager>!$_"], kABPersonPhonePagerLabel, NULL);
		if([vCardDictionary objectForKey: @"*PHONE_$!<HomeFAX>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [vCardDictionary objectForKey: @"*PHONE_$!<HomeFAX>!$_"], kABPersonPhoneHomeFAXLabel, NULL);
		
		
		for(int x = 0; x < [[vCardDictionary allKeys] count]; x++)
		{			
			if([[[vCardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[vCardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*PHONE"])
			{
				ABMultiValueAddValueAndLabel(phoneMultiValue, [vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[vCardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*PHONE" withString: @""] , NULL);	
			}
		}
		
		ABRecordSetValue(newPerson, kABPersonPhoneProperty, phoneMultiValue, ABError);
        if (phoneMultiValue) CFRelease(phoneMultiValue);
		
		//URL HANDLERS
		ABMutableMultiValueRef URLMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([vCardDictionary objectForKey: @"*URL_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [vCardDictionary objectForKey: @"*URL_$!<Home>!$_"], kABHomeLabel, NULL);
		if([vCardDictionary objectForKey: @"*URL_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [vCardDictionary objectForKey: @"*URL_$!<Work>!$_"], kABWorkLabel, NULL);
		if([vCardDictionary objectForKey: @"*URL_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [vCardDictionary objectForKey: @"*URL_$!<Other>!$_"], kABOtherLabel, NULL);
		if([vCardDictionary objectForKey: @"*URL_$!<HomePage>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [vCardDictionary objectForKey: @"*URL_$!<HomePage>!$_"], kABPersonHomePageLabel, NULL);	
		
		
		for(int x = 0; x < [[vCardDictionary allKeys] count]; x++)
		{			
			if([[[vCardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[vCardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*URL"])
			{
				ABMultiValueAddValueAndLabel(URLMultiValue, [vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[vCardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*URL" withString: @""] , NULL);	
			}
		}
		
		ABRecordSetValue(newPerson, kABPersonURLProperty, URLMultiValue, ABError);
        if (URLMultiValue) CFRelease(URLMultiValue);
		
		//Date HANDLERS
		ABMutableMultiValueRef DateMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([vCardDictionary objectForKey: @"*DATE_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [vCardDictionary objectForKey: @"*DATE_$!<Home>!$_"], kABHomeLabel, NULL);
		if([vCardDictionary objectForKey: @"*DATE_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [vCardDictionary objectForKey: @"*DATE_$!<Work>!$_"], kABWorkLabel, NULL);
		if([vCardDictionary objectForKey: @"*DATE_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [vCardDictionary objectForKey: @"*DATE_$!<Other>!$_"], kABOtherLabel, NULL);		
		
		
		for(int x = 0; x < [[vCardDictionary allKeys] count]; x++)
		{			
			if([[[vCardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[vCardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*DATE"])
			{
				ABMultiValueAddValueAndLabel(URLMultiValue, [vCardDictionary objectForKey: [[vCardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[vCardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*DATE" withString: @""] , NULL);	
			}
		}
		
		ABRecordSetValue(newPerson, kABPersonDateProperty, DateMultiValue, ABError);
        if (DateMultiValue) CFRelease(DateMultiValue);
		
		ABRecordSetValue(newPerson, kABPersonFirstNameProperty, [vCardDictionary objectForKey: @"FirstName"], ABError);
		ABRecordSetValue(newPerson, kABPersonLastNameProperty, [vCardDictionary objectForKey: @"LastName"], ABError);
		ABRecordSetValue(newPerson, kABPersonMiddleNameProperty, [vCardDictionary objectForKey: @"MiddleName"], ABError);
		ABRecordSetValue(newPerson, kABPersonOrganizationProperty, [vCardDictionary objectForKey: @"OrgName"], ABError);
		ABRecordSetValue(newPerson, kABPersonJobTitleProperty, [vCardDictionary objectForKey: @"JobTitle"], ABError);
		ABRecordSetValue(newPerson, kABPersonDepartmentProperty, [vCardDictionary objectForKey: @"Department"], ABError);
		ABRecordSetValue(newPerson, kABPersonPrefixProperty, [vCardDictionary objectForKey: @"Prefix"], ABError);
		ABRecordSetValue(newPerson, kABPersonSuffixProperty, [vCardDictionary objectForKey: @"Suffix"], ABError);
		ABRecordSetValue(newPerson, kABPersonNicknameProperty, [vCardDictionary objectForKey: @"Nickname"], ABError);
		ABPersonSetImageData (newPerson, (CFDataRef)[NSData decodeBase64ForString: [vCardDictionary objectForKey: @"contactImage"]], ABError);
		
		NSDate *today = [[NSDate alloc] init];
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"MM-dd-yyyy"];
		
		if([vCardDictionary objectForKey: @"NotesText"] != nil)
		{
			//we have no custom append message set
			if([[NSUserDefaults standardUserDefaults] objectForKey: @"appendString"] == nil)
				ABRecordSetValue(newPerson, kABPersonNoteProperty, [[vCardDictionary objectForKey: @"NotesText"] stringByAppendingString: [NSString stringWithFormat: @"\nSent by %@ on %@", lastPeerHandle, [dateFormatter stringFromDate:today]]], ABError);
			else
			{
				NSString *customAppendString = [[NSUserDefaults standardUserDefaults] objectForKey: @"appendString"];
				
				customAppendString = [customAppendString stringByReplacingOccurrencesOfString:@"$date" withString:[dateFormatter stringFromDate:today]];
				customAppendString = [customAppendString stringByReplacingOccurrencesOfString:@"$name" withString:lastPeerHandle];
				
				ABRecordSetValue(newPerson, kABPersonNoteProperty, [[vCardDictionary objectForKey: @"NotesText"] stringByAppendingString: [NSString stringWithFormat:@"\n%@", customAppendString]], ABError);
			}
		}
		else
		{
			//we have no custom append message set
			if([[NSUserDefaults standardUserDefaults] objectForKey: @"appendString"] == nil)
				ABRecordSetValue(newPerson, kABPersonNoteProperty, [NSString stringWithFormat: @"Sent by %@ on %@", lastPeerHandle, [dateFormatter stringFromDate:today] ], ABError);
			else
			{
				NSString *customAppendString = [[NSUserDefaults standardUserDefaults] objectForKey: @"appendString"];
				
				customAppendString = [customAppendString stringByReplacingOccurrencesOfString:@"$date" withString:[dateFormatter stringFromDate:today]];
				customAppendString = [customAppendString stringByReplacingOccurrencesOfString:@"$name" withString:lastPeerHandle];
				
				ABRecordSetValue(newPerson, kABPersonNoteProperty, customAppendString, ABError);				
			}
		}
		
		[dateFormatter release];
		[today release];
		
		}
	
	
	return newPerson;
}

- (NSDictionary *)sendMyVcard:(BOOL)isBounce forRecord:(ABRecordID)record
{	
	//we use this function for any card sent now, record is getting set when passed
	ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), record);
	NSMutableDictionary *vCardDictionary = [[NSMutableDictionary alloc] init];
	
	//single value objects
	[vCardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonFirstNameProperty) forKey: @"FirstName"];
	[vCardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonMiddleNameProperty) forKey: @"MiddleName"];
	[vCardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonLastNameProperty) forKey: @"LastName"];
	[vCardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonOrganizationProperty) forKey: @"OrgName"];
	[vCardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonJobTitleProperty) forKey: @"JobTitle"];
	[vCardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonDepartmentProperty) forKey: @"Department"];
	[vCardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonPrefixProperty) forKey: @"Prefix"];
	[vCardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonSuffixProperty) forKey: @"Suffix"];
	[vCardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonNicknameProperty) forKey: @"Nickname"];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey: @"allowNote"])
		[vCardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonNoteProperty) forKey: @"NotesText"];
    
    // Re-encode the image
    UIImage *contactImage = [UIImage imageWithData:(NSData *)ABPersonCopyImageData(ownerCard)];
    if (contactImage)
    {
        [vCardDictionary setValue: [UIImageJPEGRepresentation(contactImage, 0.5) encodeBase64ForData] forKey: @"contactImage"];
    }
    else
    {
        [vCardDictionary setValue: nil forKey: @"contactImage"];
    }
    
	
	//phone
    CFTypeRef abValue = ABRecordCopyValue(ownerCard , kABPersonPhoneProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[vCardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonPhoneProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*PHONE%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonPhoneProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//email
    abValue = ABRecordCopyValue(ownerCard , kABPersonEmailProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[vCardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonEmailProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*EMAIL%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonEmailProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//address
    abValue = ABRecordCopyValue(ownerCard , kABPersonAddressProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[vCardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonAddressProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*ADDRESS%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonAddressProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//URLs
    abValue = ABRecordCopyValue(ownerCard , kABPersonURLProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[vCardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonURLProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*URL%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonURLProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//IM
    abValue = ABRecordCopyValue(ownerCard , kABPersonInstantMessageProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[vCardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonInstantMessageProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*IM%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonInstantMessageProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//dates
    abValue = ABRecordCopyValue(ownerCard , kABPersonDateProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		//need to convert to string to play nice with JSON
		[vCardDictionary setValue: [(NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonDateProperty) , x) description] 
						   forKey: [NSString stringWithFormat: @"*DATE%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonDateProperty) , x)]];		
	}
    if (abValue) CFRelease(abValue);
	
	//relatives
    abValue = ABRecordCopyValue(ownerCard , kABPersonRelatedNamesProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[vCardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonRelatedNamesProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*RELATED%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonRelatedNamesProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
    
	
    return vCardDictionary;
}


@end
