//
//  HSKEmailModalViewController.m
//  Handshake
//
//  Created by Kyle on 10/28/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKEmailModalViewController.h"


@implementation HSKEmailModalViewController

@synthesize emailTextField, sendButton, delegate;

- (id)init
{
    if (self = [super initWithNibName:@"EmailModalView" bundle:nil])
    {
        self.title = NSLocalizedString(@"Email", @"Title for the Email view");
    }
    
    return self;
}    


- (void)dealloc 
{
	self.emailTextField = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark View Loading

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	self.sendButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", @"Send button in Email view") style:UIBarButtonItemStyleDone target:self action:@selector(send:)] autorelease];
    
    self.navigationItem.rightBarButtonItem = sendButton;
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease];
}

- (void)viewDidAppear:(BOOL)animated 
{
	[emailViewTable reloadData];
	
	[super viewDidAppear:animated];
    
	//accept input on load
    [self.emailTextField becomeFirstResponder];
}

#pragma mark -
#pragma mark Table View Methods 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"EmailCellIdent";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
    }
	
	
	if([indexPath section] == 0)
	{
		UITextField *emailField = [[UITextField alloc] initWithFrame:CGRectInset(cell.contentView.bounds, 12.0, 8.0)];
		
		emailField.placeholder = NSLocalizedString(@"Email Address", @"Email Address field placeholder for the Email Modal view");
        emailField.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        emailField.clearButtonMode = UITextFieldViewModeWhileEditing;
        emailField.opaque = YES;
		
		emailField.keyboardType = UIKeyboardTypeEmailAddress;
        emailField.backgroundColor = [UIColor whiteColor];
		emailField.textColor = [UIColor colorWithRed:58.0/255.0 green:86.0/255.0 blue:138.0/255.0 alpha:1.0];

		emailField.delegate = self;
		
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contentView.autoresizesSubviews = YES;
        cell.contentView.opaque = YES;
        [cell.contentView addSubview:emailField];
		
		 self.emailTextField = emailField;
	}
	
	else if([indexPath section] == 1)
	{
		cell.text = NSLocalizedString(@"Address Book", @"Address Book title in the Email view");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	
	}
	
	
    // Configure the cell
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (indexPath.section == 1)
    {
		ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
        picker.displayedProperties = [NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:kABPersonEmailProperty]];
        [self presentModalViewController:picker animated:YES];
        [picker release];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	
	if([indexPath section] == 0)
		return 70;
	

	return [tableView rowHeight];
}



#pragma mark -
#pragma mark People Picker Delegate Functions

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker 
{
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES; //allow user to continue to select indie email address, may want to guard if there is only one email and not let the user go forward.
}

//user has selected the final data
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	ABMultiValueRef mvRef = ABRecordCopyValue(person, kABPersonEmailProperty);
    CFStringRef emailAddress = ABMultiValueCopyValueAtIndex(mvRef, identifier);
		
	emailTextField.text = (NSString *) emailAddress;
	
	CFRelease(emailAddress);
    CFRelease(mvRef);
	
	[self dismissModalViewControllerAnimated:YES];
	
    return NO;
}

#pragma mark -
#pragma mark Formatting Stuff

- (BOOL)checkForProperEmailFormat
{
	//if the email contains @ and . we assume it is a valid email address, little hacky might want to revisit when we have time
	if([emailTextField.text rangeOfString:@"@"].location != NSNotFound && [emailTextField.text rangeOfString:@"."].location != NSNotFound)
	{
		return YES;
	}
	
	return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if([self checkForProperEmailFormat])
	{
		sendButton.enabled = YES;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if([self checkForProperEmailFormat])
	{
		sendButton.enabled = YES;
	}
	
	return YES;
}


#pragma mark -
#pragma mark Send/Cancel Actions

- (IBAction)cancel:(id)sender
{
	
	//FIXME: Need to set Userbusy = FALSE here
	[self.parentViewController dismissModalViewControllerAnimated: YES];
}


- (IBAction)send:(id)sender
{
	NSLog(@"Sending Email to %@", self.emailTextField);
	
	[self.parentViewController dismissModalViewControllerAnimated: YES];
}


@end
