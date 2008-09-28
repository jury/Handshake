//
//  HSKViewController.m
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//

#import "HSKMainViewController.h"
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


@implementation HSKMainViewController


// Implement viewDidLoad to do additional setup after loading the view.
//
// IJB: Do we really want this to hapen every time the view is loaded? Consider moving this 
// to app delegate initialization.
//

- (void)viewDidLoad {
		
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSString *myPhoneNumber = [[[defaults dictionaryRepresentation] objectForKey: @"SBFormattedPhoneNumber"] numericOnly];
	NSString *phoneNumber;
	BOOL foundOwner = FALSE;
	
    // Note: Due to the TouchDebugging stuff, the guards are no longer needed
	NSLog(@"We have retrived %@ from the device as the primary number", myPhoneNumber);
	
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
				UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat: @"Are you %@ %@?", firstName, lastName] delegate:self cancelButtonTitle:@"No, I Will Select Myself" destructiveButtonTitle:nil otherButtonTitles:[NSString stringWithFormat: @" Yes I am %@", firstName], nil];
				[alert showInView:self.view];
				owner = record;
				foundOwner = TRUE;
			}
			
			if(foundOwner)
				break;
		}
		
		[firstName release];
		[lastName release];
	}
	
	if(!foundOwner)
	{
		//unable to find owner, user wil have to select
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Determine Owner" message:@"Unable to determine which contact belongs to you, please select yourself" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
		[alert show];
	}
	
    [super viewDidLoad];
}

- (IBAction)sendMyVcard
{
	NSLog(@"Sending my vCard");
}
- (IBAction)sendOtherVcard
{
	NSLog(@"Sending Other vCard");
}
- (IBAction)sendPicture
{
	NSLog(@"Send Picture");
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	
	if(buttonIndex == 0)
	{
		//we have found the correct user
	}
	else if(buttonIndex == 1)
	{
		
        ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
		picker.navigationBarHidden=YES; //gets rid of the nav bar
        [self presentModalViewController:picker animated:YES];
        [picker release];
		
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
	picker.peoplePickerDelegate = self;
	picker.navigationBarHidden=YES; //gets rid of the nav bar
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker 
{
	//should never be called since we dont have a cancel button
   [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	[self dismissModalViewControllerAnimated:YES];
	
	owner = person;
	
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	//we should never get here anyways
    return NO;
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
