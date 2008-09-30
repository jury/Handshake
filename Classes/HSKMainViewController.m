//
//  HSKViewController.m
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//

#import "HSKMainViewController.h"
#import "NSString+SKPPhoneAdditions.h"


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

- (void)viewDidLoad 
{
	
	
    [super viewDidLoad];
}

- (void)sendMyVcard
{
	ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), ownerRecord);
	
	NSString *firstName = (NSString *)ABRecordCopyValue(ownerCard, kABPersonFirstNameProperty);
	NSString *lastName = (NSString *)ABRecordCopyValue(ownerCard, kABPersonLastNameProperty);
	NSString *orgName = (NSString *)ABRecordCopyValue(ownerCard, kABPersonOrganizationProperty);
	NSString *jobTitle = (NSString *)ABRecordCopyValue(ownerCard, kABPersonJobTitleProperty);
	NSString *departmentTitle = (NSString *)ABRecordCopyValue(ownerCard, kABPersonDepartmentProperty);
	
	NSLog(@"\nFirst Name: %@\nLast Name: %@\nOrgName: %@\nJob Title: %@\nDepartment: %@", firstName, lastName, orgName, jobTitle, departmentTitle);

	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonPhoneProperty)) > x); x++)
	{
		NSLog(@"Phone %i: %@", x+1 ,(NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonPhoneProperty) , x));
	}
	
	
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonEmailProperty)) > x); x++)
	{
		NSLog(@"Email %i: %@", x+1, (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonEmailProperty) , x));
	}
	
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonAddressProperty)) > x); x++)
	{
		NSLog(@"%@", (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonAddressProperty) , x));
	}
	 
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonInstantMessageProperty)) > x); x++)
	{
		NSLog(@"%@", (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonInstantMessageProperty) , x));
	}
	
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonRelatedNamesProperty)) > x); x++)
	{
		NSLog(@"%@", (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonRelatedNamesProperty) , x));
	}
	
	[firstName release];
	[lastName release];
	[orgName release];
	[jobTitle release];
	[departmentTitle release];
}

- (void)sendOtherVcard
{
	ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), otherRecord);
	
	NSString *firstName = (NSString *)ABRecordCopyValue(ownerCard, kABPersonFirstNameProperty);
	NSString *lastName = (NSString *)ABRecordCopyValue(ownerCard, kABPersonLastNameProperty);
	NSString *orgName = (NSString *)ABRecordCopyValue(ownerCard, kABPersonOrganizationProperty);
	NSString *jobTitle = (NSString *)ABRecordCopyValue(ownerCard, kABPersonJobTitleProperty);
	NSString *departmentTitle = (NSString *)ABRecordCopyValue(ownerCard, kABPersonDepartmentProperty);
	
	NSLog(@"\nFirst Name: %@\nLast Name: %@\nOrgName: %@\nJob Title: %@\nDepartment: %@", firstName, lastName, orgName, jobTitle, departmentTitle);
	
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonPhoneProperty)) > x); x++)
	{
		NSLog(@"Phone %i: %@", x+1 ,(NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonPhoneProperty) , x));
	}
	
	
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonEmailProperty)) > x); x++)
	{
		NSLog(@"Email %i: %@", x+1, (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonEmailProperty) , x));
	}
	
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonAddressProperty)) > x); x++)
	{
		NSLog(@"%@", (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonAddressProperty) , x));
	}
	
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonInstantMessageProperty)) > x); x++)
	{
		NSLog(@"%@", (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonInstantMessageProperty) , x));
	}
	
	for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValue(ownerCard , kABPersonRelatedNamesProperty)) > x); x++)
	{
		NSLog(@"%@", (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(ownerCard ,kABPersonRelatedNamesProperty) , x));
	}
	
	[firstName release];
	[lastName release];
	[orgName release];
	[jobTitle release];
	[departmentTitle release];
}

#pragma mark -
#pragma mark Alerts 
#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	
	if(buttonIndex == 0)
	{
		//we have found the correct user
	}
	else if(buttonIndex == 1)
	{
		ownerRecord = kABRecordInvalidID;
		
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

#pragma mark -
#pragma mark People Picker Functions
#pragma mark -

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker 
{
	//should never be called since we dont have a cancel button
   [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	[self dismissModalViewControllerAnimated:YES];
	
	if(ownerRecord == kABRecordInvalidID)
		ownerRecord = ABRecordGetRecordID (person);
	else
	{
		otherRecord = ABRecordGetRecordID (person);
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
		ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
		picker.navigationBarHidden=YES; //gets rid of the nav bar
        [self presentModalViewController:picker animated:YES];
        [picker release];	
			
	}
	
	if([indexPath row] == 2)
	{
		UIImagePickerController *picker = [[UIImagePickerController alloc] init];
		[picker setDelegate:self];
		picker.navigationBarHidden=YES; 
		picker.allowsImageEditing = YES;
		[self presentModalViewController:picker animated:YES];
        [picker release];	
	}
}

#pragma mark -
#pragma mark Memory 
#pragma mark -


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
