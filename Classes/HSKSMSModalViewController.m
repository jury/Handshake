//
//  SKPSMSModalView.m
//  CDBIPhone
//
//  Created by Ian Baird on 7/15/08.
//  Copyright (c) 2009, Skorpiostech, Inc.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//      * Neither the name of the Skorpiostech, Inc. nor the
//        names of its contributors may be used to endorse or promote products
//        derived from this software without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY SKORPIOSTECH, INC. ''AS IS'' AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL SKORPIOSTECH, INC. BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.//

#import "HSKSMSModalViewController.h"
#import "NSString+SKPPhoneAdditions.h"

@interface HSKSMSModalViewController ()

@property(nonatomic, retain) NSString *phoneNumber;

- (void)formatTypedPhoneNumber:(UITextField *)aTextField;

@end

@implementation HSKSMSModalViewController

@synthesize tableView, delegate, phoneNumber, textField, sendButton;

- (id)init
{
    if (self = [super initWithNibName:@"SMSModalView" bundle:nil])
    {
        self.phoneNumber = @"";
        self.title = NSLocalizedString(@"Share", @"Title for the SMS view");
    }
    
    return self;
}    

- (void)dealloc 
{
    
    self.tableView = nil;
    self.delegate = nil;
    self.phoneNumber = nil;
    self.textField = nil;
    self.sendButton = nil;
    
	[super dealloc];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	return 2;
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    NSString *countryCode = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleCountryCode];        
    if ([countryCode isEqualToString:@"US"] || [countryCode isEqualToString:@"CA"])
    {
        return (indexPath.section == 0) ? 55.0 : 44.0;
    }
    else
    {
        return (indexPath.section == 0) ? 45.0 : 44.0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
        
    if (section == 0)
    {
        NSString *countryCode = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleCountryCode];        
        if ([countryCode isEqualToString:@"US"] || [countryCode isEqualToString:@"CA"])
        {
            title = NSLocalizedString(@"Send the Handhake App Store link to a mobile phone.", @"SMS US/Canada instructions");
        }
        else
        {
            title = NSLocalizedString(@"Send the Handhake App Store link to a mobile phone. (Country code required)", @"SMS Non-US/Canada instructions");
        }
    }
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"SMSIdentifier";
	
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) 
    {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
	}
    
	// Configure the cell
    if (indexPath.section == 0)
    {
        UITextField *numberField = [[UITextField alloc] initWithFrame:CGRectInset(cell.contentView.bounds, 12.0, 8.0)];
        
        NSString *countryCode = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleCountryCode];        
        if ([countryCode isEqualToString:@"US"] || [countryCode isEqualToString:@"CA"])
        {
            numberField.font = [UIFont systemFontOfSize:36];
        }
        else
        {
            numberField.adjustsFontSizeToFitWidth = YES;
            numberField.font = [UIFont systemFontOfSize:28];
        }
        numberField.placeholder = NSLocalizedString(@"Phone", @"Phone number field placeholder for the SMS view");
        numberField.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        numberField.clearButtonMode = UITextFieldViewModeWhileEditing;
        numberField.opaque = YES;
        numberField.keyboardType = UIKeyboardTypePhonePad;
        numberField.backgroundColor = [UIColor whiteColor];
        numberField.text = self.phoneNumber;
        
        
        numberField.textColor = [UIColor colorWithRed:58.0/255.0 green:86.0/255.0 blue:138.0/255.0 alpha:1.0];
        numberField.delegate = self;

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contentView.autoresizesSubviews = YES;
        cell.contentView.opaque = YES;
        [cell.contentView addSubview:numberField];
        
        self.textField = numberField;
        
        [numberField release];
    }
    else
    {
        cell.text = NSLocalizedString(@"Address Book", @"Address Book title in the SMS view");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (indexPath.section == 1)
    {
        self.phoneNumber = self.textField.text;
        
        ABPeoplePickerNavigationController *picker =
        [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
        picker.displayedProperties = [NSArray arrayWithObject:[NSNumber numberWithUnsignedInteger:kABPersonPhoneProperty]];
        [self presentModalViewController:picker animated:YES];
        [picker release];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sendButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", @"Send button in SMS view") style:UIBarButtonItemStyleDone target:self action:@selector(send:)] autorelease];
    
    self.navigationItem.rightBarButtonItem = sendButton;
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease];
    
    sendButton.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
    
    // Remove any existing selection.
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath.row != NSNotFound)
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    
    self.tableView.sectionFooterHeight = 0.0;
    self.tableView.sectionHeaderHeight = 14.0;
    
    // Redisplay the data.
    [self.tableView reloadData];
    
    // set the status bar style
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
    
    // Set the focus
    [self.textField becomeFirstResponder];
    
    // format any text (enable/disable the send button)
    [self formatTypedPhoneNumber:self.textField];
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)aTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self performSelector:@selector(formatTypedPhoneNumber:) withObject:aTextField afterDelay:0.0];
    
    NSString *countryCode = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleCountryCode];
    if ([countryCode isEqualToString:@"US"] || [countryCode isEqualToString:@"CA"])
    {
        return (([[aTextField.text numericOnly] length] + [[string numericOnly] length]) < 11);
    }
    else
    {
        return YES;
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)aTextField
{
    [self performSelector:@selector(formatTypedPhoneNumber:) withObject:aTextField afterDelay:0.0];
    
    return YES;
}

#pragma mark -
#pragma mark timer methods

- (void)formatTypedPhoneNumber:(UITextField *)aTextField
{
    NSString *countryCode = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleCountryCode];
    if ([countryCode isEqualToString:@"US"] || [countryCode isEqualToString:@"CA"])
    {
        aTextField.text = [aTextField.text formattedUSPhoneNumber];
    
        sendButton.enabled = ([[aTextField.text numericOnly] length] == 10);
    }
    else
    {
        sendButton.enabled = ([[aTextField.text numericOnly] length] >= 4);
    }
}

#pragma mark -
#pragma mark ABPeoplePickerNavigationController delegate methods

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker 
{
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    ABMultiValueRef mvRef = ABRecordCopyValue(person, kABPersonPhoneProperty);
    CFStringRef aPhoneNumber = ABMultiValueCopyValueAtIndex(mvRef, identifier);
    
    self.phoneNumber = [(NSString *)aPhoneNumber formattedUSPhoneNumber];
    textField.text = self.phoneNumber;
    
    sendButton.enabled = YES;
    
    CFRelease(aPhoneNumber);
    CFRelease(mvRef);
    
    [self dismissModalViewControllerAnimated:YES];
    
    return NO;
}

#pragma mark -
#pragma mark event methods

- (IBAction)cancel:(id)sender
{
    if (self.delegate)
    {
        [delegate smsModalViewWasCancelled:self];
    }
}

- (IBAction)send:(id)sender
{
    if (self.delegate)
    {
        self.phoneNumber = self.textField.text;
        
        NSString *countryCode = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleCountryCode];
        if ([countryCode isEqualToString:@"US"] || [countryCode isEqualToString:@"CA"])
        {
            [delegate smsModalView:self enteredPhoneNumber:[@"1" stringByAppendingString:[self.phoneNumber numericOnly]]];
        }
        else
        {
            [delegate smsModalView:self enteredPhoneNumber:[self.phoneNumber numericOnly]];
        }
    }
}

@end

