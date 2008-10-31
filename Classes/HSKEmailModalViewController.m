//
//  HSKEmailModalViewController.m
//  Handshake
//
//  Created by Kyle on 10/28/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKEmailModalViewController.h"
#import "HSKEmailPrefsViewController.h"

@interface HSKEmailModalViewController ()

@property(nonatomic, retain) NSString *email;

- (void)checkForProperEmailFormat;

@end


@implementation HSKEmailModalViewController

@synthesize emailTextField, sendButton, delegate, email;

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
    self.email = nil;
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

- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
    
    // Remove any existing selection.
    NSIndexPath *indexPath = [emailViewTable indexPathForSelectedRow];
    if (indexPath.row != NSNotFound)
    {
        [emailViewTable deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    emailViewTable.sectionFooterHeight = 0.0;
    emailViewTable.sectionHeaderHeight = 14.0;
    
    // Redisplay the data.
    [emailViewTable reloadData];
    
    // set the status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
    
    //accept input on load
    [self.emailTextField becomeFirstResponder];
    [self performSelector:@selector(checkForProperEmailFormat) withObject:nil afterDelay:0.0];
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
		UITextField *emailField = [[UITextField alloc] initWithFrame:CGRectInset(cell.contentView.bounds, 12.0, 9.0)];
		
		emailField.placeholder = NSLocalizedString(@"Email Address", @"Email Address field placeholder for the Email Modal view");
        emailField.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        emailField.clearButtonMode = UITextFieldViewModeWhileEditing;
        emailField.opaque = YES;
		emailField.clearsOnBeginEditing = NO;
		emailField.keyboardType = UIKeyboardTypeEmailAddress;
        emailField.backgroundColor = [UIColor whiteColor];
		emailField.textColor = [UIColor colorWithRed:58.0/255.0 green:86.0/255.0 blue:138.0/255.0 alpha:1.0];
        emailField.text = self.email;
        emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;

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
        // Store the email address
        self.email = self.emailTextField.text;
        
		ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
        picker.displayedProperties = [NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:kABPersonEmailProperty]];
        [self presentModalViewController:picker animated:YES];
        [picker release];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    
    if (section == 0)
    {
        title = NSLocalizedString(@"Send this item to a friend by entering his or her email address below.", @"Email instructions");
    }
    
    return title;
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
		
	self.email = (NSString *) emailAddress;
	
	CFRelease(emailAddress);
    CFRelease(mvRef);
	
	[self dismissModalViewControllerAnimated:YES];
	
    [self performSelector:@selector(checkForProperEmailFormat) withObject:nil afterDelay:0.0];
    
    return NO;
}

#pragma mark -
#pragma mark Formatting Stuff

- (void)checkForProperEmailFormat
{
    NSUInteger atLocation = [emailTextField.text rangeOfString:@"@"].location;
    NSUInteger dotLocation = [emailTextField.text rangeOfString:@"."].location;
    
    // Contains "@", "." and "@" precedes "."
	if ((atLocation != NSNotFound) && (dotLocation != NSNotFound) && (atLocation < dotLocation))
	{
		sendButton.enabled = YES;
	}
    else
    {
        sendButton.enabled = NO;
    }
}

- (BOOL)textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self performSelector:@selector(checkForProperEmailFormat) withObject:nil afterDelay:0.0];
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)aTextField
{
    [self performSelector:@selector(checkForProperEmailFormat) withObject:nil afterDelay:0.0];
    
    return YES;
}


#pragma mark -
#pragma mark Send/Cancel Actions

- (IBAction)cancel:(id)sender
{
	
	if (self.delegate)
    {
        [delegate emailModalViewWasCancelled:self];
    }
}


- (IBAction)send:(id)sender
{
	if (self.delegate)
    {
        self.email = self.emailTextField.text;
        
        [self.emailTextField resignFirstResponder];
        
        [delegate emailModalView:self enteredEmail:self.email];
    }
}

@end
