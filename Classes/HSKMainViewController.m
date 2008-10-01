//
//  HSKViewController.m
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//

#import "HSKMainViewController.h"
#import "NSString+SKPPhoneAdditions.h"
#import "RPSNetwork.h"
#import "CJSONSerializer.h"
#import "CJSONDeserializer.h"

@interface HSKMainViewController ()

@end

@implementation HSKMainViewController


-(void)verifyOwnerCard 
{ 
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *myPhoneNumber = [[[defaults dictionaryRepresentation] objectForKey: @"SBFormattedPhoneNumber"] numericOnly];
	NSString *phoneNumber;
	BOOL foundOwner = FALSE;
	
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
				ownerRecord = ABRecordGetRecordID (record);
				
				foundOwner = TRUE;
			}
			
			if(foundOwner)
				break;
		}
		
		[firstName release];
		[lastName release];
		
		if(foundOwner)
			break;
	}
	
	if(!foundOwner)
	{
		//unable to find owner, user wil have to select
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Determine Owner" message:@"Unable to determine which contact belongs to you, please select yourself" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
		[alert show];
	}
}


-(void)recievedCard: (NSString *)string
{
	NSError *error = nil;
	NSData *JSONData = [string dataUsingEncoding: NSUTF8StringEncoding];
	
	NSDictionary *VcardDictionary = [[CJSONDeserializer deserializer] deserialize:JSONData error: &error]; 
	
	
	if(!VcardDictionary || error)
	{
		NSLog(@"%@", [error localizedDescription]);
	}
	else
	{		
		CFErrorRef *ABError = NULL;
		ABRecordRef newPerson = ABPersonCreate();

		ABMutableMultiValueRef addressMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([VcardDictionary objectForKey: @"ADDRESS_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(addressMultiValue, [VcardDictionary objectForKey: @"ADDRESS_$!<Home>!$_"], kABHomeLabel, NULL);
		if([VcardDictionary objectForKey: @"ADDRESS_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(addressMultiValue, [VcardDictionary objectForKey: @"ADDRESS_$!<Work>!$_"], kABWorkLabel, NULL);
		if([VcardDictionary objectForKey: @"ADDRESS_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(addressMultiValue, [VcardDictionary objectForKey: @"ADDRESS_$!<Other>!$_"], kABOtherLabel, NULL);
		ABRecordSetValue(newPerson, kABPersonAddressProperty, addressMultiValue, ABError);
		
		ABMutableMultiValueRef IMMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([VcardDictionary objectForKey: @"IM_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(IMMultiValue, [VcardDictionary objectForKey: @"IM_$!<Home>!$_"], kABHomeLabel, NULL);
		if([VcardDictionary objectForKey: @"IM_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(IMMultiValue, [VcardDictionary objectForKey: @"IM_$!<Work>!$_"], kABWorkLabel, NULL);
		if([VcardDictionary objectForKey: @"IM_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(IMMultiValue, [VcardDictionary objectForKey: @"IM_$!<Other>!$_"], kABOtherLabel, NULL);
		ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, IMMultiValue, ABError);
		
		ABMutableMultiValueRef emailMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([VcardDictionary objectForKey: @"EMAIL_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(emailMultiValue, [VcardDictionary objectForKey: @"EMAIL_$!<Home>!$_"], kABHomeLabel, NULL);
		if([VcardDictionary objectForKey: @"EMAIL_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(emailMultiValue, [VcardDictionary objectForKey: @"EMAIL_$!<Work>!$_"], kABWorkLabel, NULL);
		if([VcardDictionary objectForKey: @"EMAIL_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(emailMultiValue, [VcardDictionary objectForKey: @"EMAIL_$!<Other>!$_"], kABOtherLabel, NULL);
		ABRecordSetValue(newPerson, kABPersonEmailProperty, emailMultiValue, ABError);
		
		ABMutableMultiValueRef relatedMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([VcardDictionary objectForKey: @"RELATED_$!<Mother>!$_"] != nil)
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"RELATED_$!<Mother>!$_"], kABPersonMotherLabel, NULL);
		if([VcardDictionary objectForKey: @"RELATED_$!<Father>!$_"] != nil)
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"RELATED_$!<Father>!$_"], kABPersonFatherLabel, NULL);
		if([VcardDictionary objectForKey: @"RELATED_$!<Parent>!$_"] != nil)
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"RELATED_$!<Parent>!$_"], kABPersonParentLabel, NULL);
		if([VcardDictionary objectForKey: @"RELATED_$!<Sister>!$_"] != nil)
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"RELATED_$!<Sister>!$_"], kABPersonSisterLabel, NULL);
		if([VcardDictionary objectForKey: @"RELATED_$!<Brother>!$_"] != nil)
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"RELATED_$!<Brother>!$_"], kABPersonBrotherLabel, NULL);
		if([VcardDictionary objectForKey: @"RELATED_$!<Child>!$_"] != nil)
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"RELATED_$!<Child>!$_"], kABPersonChildLabel, NULL);
		if([VcardDictionary objectForKey: @"RELATED_$!<Friend>!$_"] != nil)
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"RELATED_$!<Friend>!$_"], kABPersonFriendLabel, NULL);
		if([VcardDictionary objectForKey: @"RELATED_$!<Partner>!$_"] != nil)
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"RELATED_$!<Partner>!$_"], kABPersonPartnerLabel, NULL);
		if([VcardDictionary objectForKey: @"RELATED_$!<Manager>!$_"] != nil)
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"RELATED_$!<Manager>!$_"], kABPersonManagerLabel, NULL);
		if([VcardDictionary objectForKey: @"RELATED_$!<Assistant>!$_"] != nil)
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"RELATED_$!<Assistant>!$_"], kABPersonAssistantLabel, NULL);
		if([VcardDictionary objectForKey: @"RELATED_$!<Spouse>!$_"] != nil)
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"RELATED_$!<Spouse>!$_"], kABPersonSpouseLabel, NULL);
		ABRecordSetValue(newPerson, kABPersonRelatedNamesProperty, relatedMultiValue, ABError);
		
		ABMutableMultiValueRef phoneMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([VcardDictionary objectForKey: @"PHONE_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: @"PHONE_$!<Home>!$_"], kABHomeLabel, NULL);
		if([VcardDictionary objectForKey: @"PHONE_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: @"PHONE_$!<Work>!$_"], kABWorkLabel, NULL);
		if([VcardDictionary objectForKey: @"PHONE_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: @"PHONE_$!<Other>!$_"], kABOtherLabel, NULL);
		if([VcardDictionary objectForKey: @"PHONE_$!<Mobile>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: @"PHONE_$!<Mobile>!$_"], kABPersonPhoneMobileLabel, NULL);
		ABRecordSetValue(newPerson, kABPersonPhoneProperty, phoneMultiValue, ABError);
		
		
		
		
		ABRecordSetValue(newPerson, kABPersonFirstNameProperty, [VcardDictionary objectForKey: @"FirstName"], ABError);
		ABRecordSetValue(newPerson, kABPersonLastNameProperty, [VcardDictionary objectForKey: @"LastName"], ABError);
		ABRecordSetValue(newPerson, kABPersonMiddleNameProperty, [VcardDictionary objectForKey: @"MiddleName"], ABError);
		ABRecordSetValue(newPerson, kABPersonOrganizationProperty, [VcardDictionary objectForKey: @"OrgName"], ABError);
		ABRecordSetValue(newPerson, kABPersonJobTitleProperty, [VcardDictionary objectForKey: @"JobTitle"], ABError);
		ABRecordSetValue(newPerson, kABPersonDepartmentProperty, [VcardDictionary objectForKey: @"Department"], ABError);
		ABRecordSetValue(newPerson, kABPersonPrefixProperty, [VcardDictionary objectForKey: @"Prefix"], ABError);
		ABRecordSetValue(newPerson, kABPersonSuffixProperty, [VcardDictionary objectForKey: @"Suffix"], ABError);
		ABRecordSetValue(newPerson, kABPersonNicknameProperty, [VcardDictionary objectForKey: @"Nickname"], ABError);
		ABRecordSetValue(newPerson, kABPersonNoteProperty, [VcardDictionary objectForKey: @"NotesText"], ABError);


		
		ABUnknownPersonViewController *unknownPersonViewController = [[ABUnknownPersonViewController alloc] init];
		unknownPersonViewController.displayedPerson = newPerson;
		unknownPersonViewController.allowsActions = YES;
		unknownPersonViewController.allowsAddingToAddressBook = YES;
		unknownPersonViewController.unknownPersonViewDelegate = self;
		[self presentModalViewController:unknownPersonViewController animated:YES];
		
		CFRelease(newPerson);
	}
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
}

- (void)sendMyVcard
{
	ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), ownerRecord);
	
	NSMutableDictionary *VcardDictionary = [[NSMutableDictionary alloc] initWithCapacity:1]; 
	
	//single value objects
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonFirstNameProperty) forKey: @"FirstName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonMiddleNameProperty) forKey: @"MiddleName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonLastNameProperty) forKey: @"LastName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonOrganizationProperty) forKey: @"OrgName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonJobTitleProperty) forKey: @"JobTitle"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonDepartmentProperty) forKey: @"Department"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonPrefixProperty) forKey: @"Prefix"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonSuffixProperty) forKey: @"Suffix"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonNicknameProperty) forKey: @"Nickname"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonNoteProperty) forKey: @"NotesText"];

	//phone
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonPhoneProperty)) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonPhoneProperty) , x) 
						   forKey: [NSString stringWithFormat: @"PHONE%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonPhoneProperty) , x)]];
	}
	
	//email
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonEmailProperty)) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonEmailProperty) , x) 
						   forKey: [NSString stringWithFormat: @"EMAIL%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonEmailProperty) , x)]];
	}
	
	//address
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonAddressProperty)) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonAddressProperty) , x) 
						   forKey: [NSString stringWithFormat: @"ADDRESS%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonAddressProperty) , x)]];
	}
	
	//URLs
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonURLProperty)) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonURLProperty) , x) 
						   forKey: [NSString stringWithFormat: @"URL%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonURLProperty) , x)]];
	}
	
	//IM
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonInstantMessageProperty)) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonInstantMessageProperty) , x) 
						   forKey: [NSString stringWithFormat: @"IM%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonInstantMessageProperty) , x)]];
	}
	
	//dates
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonDateProperty)) > x); x++)
	{
		//need to convert to string to play nice with JSON
		[VcardDictionary setValue: [(NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonDateProperty) , x) description] 
						   forKey: [NSString stringWithFormat: @"DATE%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonDateProperty) , x)]];		
	}
	
	//relatives 
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonRelatedNamesProperty)) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonRelatedNamesProperty) , x) 
						   forKey: [NSString stringWithFormat: @"RELATED%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonRelatedNamesProperty) , x)]];
	}
	
	
	//NSLog(@"%@", [[CJSONSerializer serializer] serializeDictionary: VcardDictionary]);
	
	[self recievedCard:  [[CJSONSerializer serializer] serializeDictionary: VcardDictionary]];
}

- (void)sendOtherVcard
{
	ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), otherRecord);

	NSMutableDictionary *VcardDictionary = [[NSMutableDictionary alloc] initWithCapacity:1]; 
	
	//single value objects
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonFirstNameProperty) forKey: @"FirstName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonMiddleNameProperty) forKey: @"MiddleName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonLastNameProperty) forKey: @"LastName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonOrganizationProperty) forKey: @"OrgName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonJobTitleProperty) forKey: @"JobTitle"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonDepartmentProperty) forKey: @"Department"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonPrefixProperty) forKey: @"Prefix"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonSuffixProperty) forKey: @"Suffix"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonNicknameProperty) forKey: @"Nickname"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValue(ownerCard, kABPersonNoteProperty) forKey: @"NotesText"];
	
	//phone
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonPhoneProperty)) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonPhoneProperty) , x) 
						   forKey: [NSString stringWithFormat: @"PHONE%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonPhoneProperty) , x)]];
	}
	
	//email
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonEmailProperty)) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonEmailProperty) , x) 
						   forKey: [NSString stringWithFormat: @"EMAIL%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonEmailProperty) , x)]];
	}
	
	//address
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonAddressProperty)) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonAddressProperty) , x) 
						   forKey: [NSString stringWithFormat: @"ADDRESS%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonAddressProperty) , x)]];
	}
	
	//URLs
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonURLProperty)) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonURLProperty) , x) 
						   forKey: [NSString stringWithFormat: @"URL%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonURLProperty) , x)]];
	}
	
	//IM
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonInstantMessageProperty)) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonInstantMessageProperty) , x) 
						   forKey: [NSString stringWithFormat: @"IM%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonInstantMessageProperty) , x)]];
	}
	
	//dates
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonDateProperty)) > x); x++)
	{
		//need to convert to string to play nice with JSON
		[VcardDictionary setValue: [(NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonDateProperty) , x) description] 
						   forKey: [NSString stringWithFormat: @"DATE%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonDateProperty) , x)]];		
	}
	
	//relatives 
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonRelatedNamesProperty)) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonRelatedNamesProperty) , x) 
						   forKey: [NSString stringWithFormat: @"RELATED%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValue(ownerCard ,kABPersonRelatedNamesProperty) , x)]];
	}
	
	CJSONSerializer *jsoned = [[CJSONSerializer alloc] init];
	
	NSLog(@"%@", [jsoned serializeDictionary: VcardDictionary]);
	
	[jsoned release];
}

#pragma mark -
#pragma mark Alerts 
#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	
	if(buttonIndex == 0)
	{
		//we have found the correct user
		primaryCardSelecting = FALSE;
	}
	
	//we missed the mark for correct owner, user will select
	else if(buttonIndex == 1)
	{
		primaryCardSelecting = TRUE;
		
        ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
		picker.navigationBarHidden=YES; //gets rid of the nav bar
        [self presentModalViewController:picker animated:YES];
        [picker release];
		
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	primaryCardSelecting = TRUE;
	
	ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
	picker.peoplePickerDelegate = self;
	picker.navigationBarHidden=YES; //gets rid of the nav bar
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

#pragma mark -
#pragma mark People Picker Functions
#pragma mark -

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker 
{

	[self dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	[self dismissModalViewControllerAnimated:YES];
	
	if(primaryCardSelecting)
	{
		ownerRecord = ABRecordGetRecordID(person);
	}
	else
	{
		otherRecord = ABRecordGetRecordID(person);
		[self sendOtherVcard];
	}
	
	//self.ownerCard = (id)person;
	
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	//we should never get here anyways
    return NO;
}
#pragma mark -
#pragma mark image picker 
#pragma mark -

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
	
	[self dismissModalViewControllerAnimated:YES];
	
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissModalViewControllerAnimated:YES];
	
}


#pragma mark -
#pragma mark Table Functions
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{

	return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	
	static NSString *MyIdentifier = @"MyIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
	}
	
	if([indexPath section] == 0)
	{
		if([indexPath row] == 0)
		{
			cell.text = @"Send My vCard";
			[cell setImage:  [UIImage imageNamed: @"vcard.png"]];
		}
		else if ([indexPath row] == 1)
		{
			cell.text = @"Send Another vCard";
			[cell setImage:  [UIImage imageNamed: @"ab.png"]];
		}
		else if ([indexPath row] == 2)
		{
			cell.text = @"Send a Picture";
			[cell setImage:  [UIImage imageNamed: @"pict.png"]];
		}
	}
	
		
	//adds the disclose indictator. 
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	// Configure the cell
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//do that HIG glow thing that apple likes so much
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
	
	//send my vCard
	if ([indexPath row] == 0)
	{
		[self sendMyVcard];
	}
	
	//send someone elses card
	if ([indexPath row] == 1)
	{
		primaryCardSelecting = FALSE;
		ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
		picker.navigationBarHidden=NO;
        [self presentModalViewController:picker animated:YES];
        [picker release];	
			
	}
	
	if([indexPath row] == 2)
	{
		UIImagePickerController *picker = [[UIImagePickerController alloc] init];
		[picker setDelegate:self];
		picker.navigationBarHidden=YES; 
		picker.allowsImageEditing = NO;
		[self presentModalViewController:picker animated:YES];
        [picker release];	
	}
}

#pragma mark -
#pragma mark Memory 
#pragma mark -

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonViewController
                 didResolveToPerson:(ABRecordRef)person 
{
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
  
	
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	
	//return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
	
	
    [super dealloc];
}

@end
