//
//  HandshakeViewController.m
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//

#define DEBUG

#import "HandshakeViewController.h"
#import "AddressBook/AddressBook.h"


@interface NSString (SKPPhoneAdditions)

-(NSString *)numericOnly;
-(NSString *)formattedUSPhoneNumber;

@end

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


@implementation HandshakeViewController

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
		
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSString *myPhoneNumber = [[[defaults dictionaryRepresentation] objectForKey: @"SBFormattedPhoneNumber"] numericOnly];
	NSString *phoneNumber;
	
	#ifdef DEBUG
	NSLog(@"We have retrived %@ from the device as the primary number", myPhoneNumber);
	#endif
	
	ABAddressBookRef addressBook = ABAddressBookCreate();
	
	NSArray *addresses = (NSArray *) ABAddressBookCopyArrayOfAllPeople(addressBook);
	NSInteger addressesCount = [addresses count];
	
	for (int i = 0; i < addressesCount; i++)
	{
		ABRecordRef record = [addresses objectAtIndex:i];
		NSString *firstName = (NSString *)ABRecordCopyValue(record, kABPersonFirstNameProperty);
		NSString *lastName = (NSString *)ABRecordCopyValue(record, kABPersonLastNameProperty);
	
		NSArray *people = (NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook); 
		
		for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue([people objectAtIndex: i] , kABPersonPhoneProperty)) > x); x++)
		{
			//get phone number and strip out anything that isnt a number
			phoneNumber = [(NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue([people objectAtIndex: i] ,kABPersonPhoneProperty) , x) numericOnly];
		
			//compares the phone numbers by suffix incase user is using a 11, 10, or 7 digit number
			if([myPhoneNumber hasSuffix: phoneNumber] && [phoneNumber length] >= 7) //want to make sure we arent testing for numbers that are too short to be real
			{
				NSLog(@"Are you %@ %@?", firstName, lastName);
			}
			
		}
		
		[firstName release];
		[lastName release];
	}
	
    [super viewDidLoad];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
    [super dealloc];
}

@end
