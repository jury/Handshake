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

@property(nonatomic, retain) id ownerCard;

@end

@implementation HSKMainViewController

@synthesize ownerCard;

-(void)awakeFromNib 
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
				self.ownerCard = (id)record;
				
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

- (void)viewDidLoad {
	
	
    [super viewDidLoad];
}

- (IBAction)sendMyVcard
{
	NSString *firstName = (NSString *)ABRecordCopyValue(ownerCard, kABPersonFirstNameProperty);
	NSString *lastName = (NSString *)ABRecordCopyValue(ownerCard, kABPersonLastNameProperty);
	NSString *orgName = (NSString *)ABRecordCopyValue(ownerCard, kABPersonOrganizationProperty);
	NSString *jobTitle = (NSString *)ABRecordCopyValue(ownerCard, kABPersonJobTitleProperty);
	NSString *departmentTitle = (NSString *)ABRecordCopyValue(ownerCard, kABPersonDepartmentProperty);
	NSString *emailAddy = (NSString *)ABRecordCopyValue(ownerCard, kABPersonEmailProperty);
	
	NSLog(@"\nFirst Name: %@\nLast Name: %@\nOrgName: %@\nJob Title: %@\nDepartment: %@\nEmail: %@", firstName, lastName, orgName, jobTitle, departmentTitle, emailAddy);

	
//	NSArray *address =  (NSArray *)	ABMultiValueCopyArrayOfAllValues (kABPersonAddressProperty);
//	NSLog(@"%@", address);

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
	
	self.ownerCard = (id)person;
	
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	//we should never get here anyways
    return NO;
}


#pragma mark -
#pragma mark Table Functions
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
	//modify if you want to use more then 1 table section
	return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	if(section == 0)
		return 3;
	else
		return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
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
	
	else
	{
		if([indexPath row] == 0)
		{
			cell.text = @"Receive";
			[cell setImage:  [UIImage imageNamed: @"receive.png"]];
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
	
	self.ownerCard = nil;
    [super dealloc];
}

@end
