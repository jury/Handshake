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


@class HSKEmailModalViewController;

@protocol HSKEmailModalViewController

@required
- (void)emailModalViewWasCancelled:(HSKEmailModalViewController *)smsModalView;
- (void)emailModalView:(HSKEmailModalViewController *)smsModalView enteredEmail:(NSString *)email;

@end

@interface HSKEmailModalViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, ABPeoplePickerNavigationControllerDelegate, UIPickerViewDelegate>
{
	UITableView *emailViewTable;
	UIBarButtonItem *sendButton;

	UITextField *emailTextField;	
	
	id <HSKEmailModalViewController> delegate;

}

@property(nonatomic, retain) UITextField *emailTextField;
@property(nonatomic, retain) UIBarButtonItem *sendButton;
@property(nonatomic, assign) id <HSKEmailModalViewController> delegate;


- (IBAction)cancel:(id)sender;
- (IBAction)send:(id)sender;
- (BOOL)checkForProperEmailFormat;

@end
