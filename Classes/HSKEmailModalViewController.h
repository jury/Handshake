//
//  HSKEmailModalViewController.h
//  Handshake
//
//  Created by Kyle on 10/28/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface HSKEmailModalViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, ABPeoplePickerNavigationControllerDelegate, UIPickerViewDelegate>
{
	UITableView *emailViewTable;
	UIBarButtonItem *sendButton;

	UITextField *emailTextField;	
}

@property(nonatomic, retain) UITextField *emailTextField;
@property(nonatomic, retain) UIBarButtonItem *sendButton;


- (IBAction)cancel:(id)sender;
- (IBAction)send:(id)sender;

@end
