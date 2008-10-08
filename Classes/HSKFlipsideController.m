//
//  flipsideController.m
//  Handshake
//
//  Created by Kyle on 10/5/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKFlipsideController.h"
#import "UIImage+ThumbnailExtensions.h"


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
		userName = [NSString stringWithFormat: @"%@ %@", (NSString *)ABRecordCopyValue(ownerCard, kABPersonFirstNameProperty),  (NSString *)ABRecordCopyValue(ownerCard, kABPersonLastNameProperty)];
	}
	
	[userName retain];
	
	if([[NSUserDefaults standardUserDefaults] objectForKey: @"avatarData"] == nil)
	{
		avatar = ABPersonHasImageData (ownerCard) ? [UIImage imageWithData: (NSData *)ABPersonCopyImageData(ownerCard)] : [UIImage imageNamed: @"defaultavatar.png"];
	}
	else
	{
		avatar = [UIImage imageWithData: [[NSUserDefaults standardUserDefaults] objectForKey: @"avatarData"]];
	}
		
		
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
		return 2;
	if(section == 1)
		return 2;

	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{	
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil] autorelease];
	
	if([indexPath section]==0)
	{
		if([indexPath row] == 0)
		{
			cell.text = @"User Name ";
			UITextField *textField = [[UITextField alloc] initWithFrame: CGRectMake(108, 12, 175, 20)];
			textField.delegate = self;
			textField.text = userName;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;			
			[cell.contentView addSubview: textField];
			[textField release];
		}
		if([indexPath row] == 1)
		{
			cell.text = @"             Change Avatar";
			UIImageView *imageView = [[UIImageView alloc] initWithImage: [avatar thumbnail:CGSizeMake(64.0, 64.0)]];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;
			[cell.contentView addSubview: imageView];
			cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		}
	}
	
	if([indexPath section]==1)
	{
	/*	if([indexPath row] == 0)
		{
			UISwitch *switchButton = [[UISwitch alloc] initWithFrame:  CGRectOffset(cell.contentView.bounds, 200.0, 8.0)] ; 
			switchButton.isOn = allowImageEdit;
			[switchButton addTarget:  self	action:@selector(toggleSwitch) forControlEvents: UIControlEventValueChanged];
			[cell.contentView addSubview: switchButton];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;
			cell.text = @"Allow Image Resize";
		} */
		
		if([indexPath row] == 0)
		{
			UISwitch *switchButton = [[UISwitch alloc] initWithFrame:  CGRectOffset(cell.contentView.bounds, 200.0, 8.0)] ; 
			switchButton.isOn = allowNote;
			[switchButton addTarget:self action:@selector(toggleSwitchNotes) forControlEvents: UIControlEventValueChanged];
			[cell.contentView addSubview: switchButton];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;
			cell.text = @"Send Notes Field";
		}
		
		if([indexPath row] == 1)
		{
			cell.text = @"Select My Card";
			cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;
		}
	}

	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section == 0)
		return @"My Info";
	if(section == 1)
		return @"Settings";
	
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if(section == 1)
		return @"\nHandshake is a joint venture between Skorpiostech Inc. and Dragon Forged Software.";
	
	return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([indexPath row] == 1 && [indexPath section] == 0)
		return 66.0;
	
	return [tableView rowHeight];
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
	[[NSUserDefaults standardUserDefaults] setBool:!allowNote forKey: @"allowNote"];
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
		
	if([indexPath section] == 1 && [indexPath row] == 1)
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
	[self refreshOwnerData];
	[viewController dismissModalViewControllerAnimated:YES];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Owner Set" message:@"You have set a new owner card." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
	[alert show];
	[alert release];

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
