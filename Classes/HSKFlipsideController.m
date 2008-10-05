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

- (void) init
{
	ABRecordID ownerRecord = [[NSUserDefaults standardUserDefaults] integerForKey:@"ownerRecordRef"];
	ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), ownerRecord);
	
	avatar = ABPersonHasImageData (ownerCard) ? [UIImage imageWithData: (NSData *)ABPersonCopyImageData(ownerCard)] : [UIImage imageNamed: @"defaultavatar.png"];
	
	[avatar retain];
	
	[super init];
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
	static NSString *MyIdentifier = @"MyIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
	}
	
	if([indexPath section]==0)
	{
		if([indexPath row] == 0)
		{
			cell.text = @"User Name: ";
			UITextField *textField = [[UITextField alloc] initWithFrame: CGRectOffset(cell.contentView.bounds, 108.0, 11.0)];
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
		if([indexPath row] == 0)
		{
			UISwitch *switchButton = [[UISwitch alloc] initWithFrame:  CGRectOffset(cell.contentView.bounds, 200.0, 8.0)] ; 
			[cell.contentView addSubview: switchButton];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.contentView.autoresizesSubviews = NO;
			
			cell.text = @"Allow Image Resize";
		}
		if([indexPath row] == 1)
		{
			cell.text = @"Select New Owner Card";
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
		return @"\nAbout: Ian loves the manly cock.";
	
	return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([indexPath row] == 1 && [indexPath section] == 0)
		return 64;
	
	return [tableView rowHeight];
}

-(void) dealloc
{

	NSLog(@"Dealloc");
	[super dealloc];
}



@end
