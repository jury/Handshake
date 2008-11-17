//
//  flipsideController.m
//  Handshake
//
//  Created by Kyle on 10/5/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKFlipsideController.h"
#import "UIImage+HSKExtensions.h"
#import "HSKMainViewController.h"
#import "HSKAboutViewController.h"
#import "HSKEmailPrefsViewController.h"
#import "HSKAppendView.h"


@implementation HSKFlipsideController


- (void)refreshOwnerData
{
	ABRecordID ownerRecord = [[NSUserDefaults standardUserDefaults] integerForKey:@"ownerRecordRef"];
	ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), ownerRecord);
	//if we have a name in defaults set it, if we dont set the vCard Name
	if([[NSUserDefaults standardUserDefaults] stringForKey: @"ownerNameString"] != nil)
	{
		userName = [[NSUserDefaults standardUserDefaults] stringForKey: @"ownerNameString"] ;
	}
	else
	{
		//nil guards
		if((NSString *)ABRecordCopyValue(ownerCard, kABPersonFirstNameProperty) != nil && (NSString *)ABRecordCopyValue(ownerCard, kABPersonLastNameProperty) != nil)
			userName = [NSString stringWithFormat:@"%@ %@", (NSString *)ABRecordCopyValue(ownerCard, kABPersonFirstNameProperty),(NSString *)ABRecordCopyValue(ownerCard, kABPersonLastNameProperty)];
		else if((NSString *)ABRecordCopyValue(ownerCard, kABPersonFirstNameProperty) != nil)
			userName = (NSString *)ABRecordCopyValue(ownerCard, kABPersonFirstNameProperty);
		else if((NSString *)ABRecordCopyValue(ownerCard, kABPersonLastNameProperty) != nil)
			userName = (NSString *)ABRecordCopyValue(ownerCard, kABPersonLastNameProperty);
		else
			userName = (NSString *)ABRecordCopyValue(ownerCard, kABPersonOrganizationProperty);	}
	
	[userName retain];
	
	if([[NSUserDefaults standardUserDefaults] objectForKey: @"avatarData"] == nil)
	{
		avatar = ABPersonHasImageData (ownerCard) ? [UIImage imageWithData: (NSData *)ABPersonCopyImageData(ownerCard)] : [UIImage imageNamed: @"defaultavatar.png"];
		UIImage *roundedAvatarImage = [[avatar thumbnail:CGSizeMake(64.0, 64.0)] roundCorners:CGSizeMake(7.0, 7.0)];
		[[NSUserDefaults standardUserDefaults] setObject: UIImagePNGRepresentation(roundedAvatarImage) forKey: @"avatarData"];
		[[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: @"avatarDate"];
	}
			
		
	allowPreview  = [[NSUserDefaults standardUserDefaults] boolForKey: @"allowPreview"];
	allowNote = [[NSUserDefaults standardUserDefaults] boolForKey: @"allowNote"];
	allowImageEdit = [[NSUserDefaults standardUserDefaults] boolForKey: @"allowImageEdit"];
	
	
	[avatar retain];	
	
	[flipsideTable reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{

	if(section == 0)
		return 1;
	if(section == 1)
		return 5;

	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{	
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil] autorelease];
	
	if([indexPath section]==0)
	{
		if([indexPath row] == 0)
		{
			cell.text = [NSString stringWithFormat: NSLocalizedString(@"            %@", @"Settings view - user name format string - probably won't need to be localized"), userName];
			cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;
			
			UIImageView *imageView = [[UIImageView alloc] initWithImage: [UIImage imageWithData: [[NSUserDefaults standardUserDefaults] objectForKey: @"avatarData"]]];
			imageView.bounds = CGRectInset( CGRectMake(0, 0, 64, 64), 2, 2);
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;
			[cell.contentView addSubview: imageView];

        }
	}
	
	if([indexPath section]==1)
	{		
		if([indexPath row] == 0)
		{
			UISwitch *switchButton = [[UISwitch alloc] initWithFrame:  CGRectOffset(cell.contentView.bounds, 200.0, 8.0)] ; 
			switchButton.isOn = allowNote;
			[switchButton addTarget:self action:@selector(toggleSwitchNotes) forControlEvents: UIControlEventValueChanged];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;
			cell.text = NSLocalizedString(@"Include Notes", @"Settings view - Include Notes switch title");
			[cell.contentView addSubview: switchButton];

			
			[switchButton release];
		}
		
		if([indexPath row] == 1)
		{
			UISwitch *switchButton = [[UISwitch alloc] initWithFrame:  CGRectOffset(cell.contentView.bounds, 200.0, 8.0)] ; 
			switchButton.isOn = allowPreview;
			[switchButton addTarget:self action:@selector(toggleSwitchPreview) forControlEvents: UIControlEventValueChanged];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;
			cell.text = NSLocalizedString(@"Preview Other Card", @"Settings view - Preview Other Card switch title");
			[cell.contentView addSubview: switchButton];

			
			[switchButton release];
		}
		
		if([indexPath row] == 2)
		{
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

		//	cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;
			cell.text = NSLocalizedString(@"Change Appended Note", @"Settings view - Change Appended Note title");
		}
		
        if([indexPath row] == 3)
		{
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            //	cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;
			cell.text = NSLocalizedString(@"Email Settings", @"Settings view - Change Email Settings");
		}
        
		if([indexPath row] == 4)
		{
		//	cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;
			cell.text = NSLocalizedString(@"About Handshake…", @"Settings view - About Handshake title");
		}
	}
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section == 0)
		return NSLocalizedString(@"My Card", @"Settings view - My Card section title");
	if(section == 1)
		return NSLocalizedString(@"Additional Settings", @"Settings view - Additional Settings title");
	
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{

	return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([indexPath row] == 0 && [indexPath section] == 0)
		return 66.0;
	
	return [tableView rowHeight];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath: [tableView indexPathForSelectedRow] animated: YES];
	
	//change appended name
	if([indexPath section] == 1 && [indexPath row] == 2)
	{
		HSKAppendView *appendViewController = [[HSKAppendView alloc] initWithNibName: @"appendScreen" bundle: nil];		
		[viewController.navigationController pushViewController:appendViewController animated:YES];
		[appendViewController release];
	}
    
    if([indexPath section] == 1 && [indexPath row] == 3)
	{
        HSKEmailPrefsViewController *emailPrefsController = [[HSKEmailPrefsViewController alloc] initWithNibName:@"HSKPrefsTableViewController" bundle:nil];
        [viewController.navigationController pushViewController:emailPrefsController animated:YES];
        [emailPrefsController release];
	}
	
	if([indexPath section] == 1 && [indexPath row] == 4)
	{
		HSKAboutViewController *aboutViewController = [[HSKAboutViewController alloc] initWithNibName: @"about" bundle: nil];		
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:aboutViewController];
		aboutViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss:)] autorelease];
		[viewController presentModalViewController:navController animated: YES];
		[navController release];
		[aboutViewController release];
	}
}

- (IBAction)dismiss:(id)sender
{
	[viewController dismissModalViewControllerAnimated: YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[[NSUserDefaults standardUserDefaults] setObject: textField.text forKey:@"ownerNameString"];	
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[[NSUserDefaults standardUserDefaults] setObject: textField.text forKey:@"ownerNameString"];
	[textField resignFirstResponder];
	
	return YES;
}
			
- (void)toggleSwitch
{
	[[NSUserDefaults standardUserDefaults] setBool:!allowImageEdit forKey: @"allowImageEdit"];
}

- (void)toggleSwitchNotes
{
	allowNote = !allowNote;

	[[NSUserDefaults standardUserDefaults] setBool:allowNote forKey: @"allowNote"];
	
	
	//true
	if(allowNote)
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
															message:NSLocalizedString(@"By choosing this option, Handshake will include the Notes field in any contact you send someone else. Please be sure you have no passwords or sensitive information in the Notes fields of your contacts before proceeding.", @"Settings view - Include Notes warning message") 
														   delegate:nil 
												  cancelButtonTitle:nil 
												  otherButtonTitles:NSLocalizedString(@"Dismiss", @"Dismiss button title"),nil];
		[alertView show];
		[alertView release];
	}
}

- (void)toggleSwitchPreview
{
	allowPreview = !allowPreview;
	
	[[NSUserDefaults standardUserDefaults] setBool:allowPreview forKey: @"allowPreview"];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if([indexPath section] == 0 && [indexPath row] == 1)
	{
		UIImagePickerController *picker = [[UIImagePickerController alloc] init];
		[picker setDelegate:self];
		picker.navigationBarHidden=NO; 
		picker.allowsImageEditing = YES;
		[viewController presentModalViewController:picker animated:YES];
        [picker release];	
	}
		
	if([indexPath section] == 0 && [indexPath row] == 0)
	 {
		 ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
		 picker.peoplePickerDelegate = self;
		 picker.navigationBarHidden= NO; 
		 [viewController presentModalViewController:picker animated:YES];
		 [picker release];
	}
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker 
{

	[viewController dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	[[NSUserDefaults standardUserDefaults] setInteger: ABRecordGetRecordID(person) forKey:@"ownerRecordRef"];
	
	
	avatar = ABPersonHasImageData (person) ? [UIImage imageWithData: (NSData *)ABPersonCopyImageData(person)] : [UIImage imageNamed: @"defaultavatar.png"];
	UIImage *roundedAvatarImage = [[avatar thumbnail:CGSizeMake(64.0, 64.0)] roundCorners:CGSizeMake(7.0, 7.0)];
	[[NSUserDefaults standardUserDefaults] setObject: UIImagePNGRepresentation(roundedAvatarImage) forKey: @"avatarData"];
	[[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: @"avatarDate"];
	
	
	[self refreshOwnerData];
	[viewController dismissModalViewControllerAnimated:YES];

    [viewController verifyOwnerCard];

    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	
    return NO;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
	[[NSUserDefaults standardUserDefaults] setObject: UIImagePNGRepresentation([image thumbnail:CGSizeMake(64.0, 64.0)]) forKey:@"avatarData"];
	[self refreshOwnerData];
	[viewController dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[viewController dismissModalViewControllerAnimated:YES];
}

-(void) dealloc
{
	[userName release];
	[avatar release];
	
	[super dealloc];
}

@end
