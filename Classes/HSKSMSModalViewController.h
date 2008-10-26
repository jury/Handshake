//
//  SKPSMSModalView.h
//  CDBIPhone
//
//  Created by Ian Baird on 7/15/08.
//  Copyright 2008 Skorpiostech, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@class HSKSMSModalViewController;

@protocol HSKSMSModalViewControllerDelegate

@required
- (void)smsModalViewWasCancelled:(HSKSMSModalViewController *)smsModalView;
- (void)smsModalView:(HSKSMSModalViewController *)smsModalView enteredPhoneNumber:(NSString *)strippedPhoneNumber;

@end

@interface HSKSMSModalViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, ABPeoplePickerNavigationControllerDelegate, UIPickerViewDelegate>
{
    IBOutlet UITableView *tableView;
    IBOutlet UIPickerView *regionPickerView;
    UIBarButtonItem *sendButton;
    
    id <HSKSMSModalViewControllerDelegate> delegate;
    
    NSString *phoneNumber;
    UITextField *textField;
}

@property(nonatomic, retain) UITableView *tableView;
@property(nonatomic, retain) UIBarButtonItem *sendButton;
@property(nonatomic, assign) id <HSKSMSModalViewControllerDelegate> delegate;
@property(nonatomic, retain) UITextField *textField;

- (IBAction)cancel:(id)sender;
- (IBAction)send:(id)sender;

@end
