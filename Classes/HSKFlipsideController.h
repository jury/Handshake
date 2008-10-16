//
//  flipsideController.h
//  Handshake
//
//  Created by Kyle on 10/5/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <QuartzCore/QuartzCore.h>


@class HSKMainViewController;

@interface HSKFlipsideController : NSObject <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ABPeoplePickerNavigationControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
	IBOutlet UITableView *flipsideTable;

	NSString *userName;
	BOOL allowImageEdit;
	BOOL allowNote;
	UIImage *avatar;
	IBOutlet HSKMainViewController *viewController;	
	IBOutlet UIView *aboutView;
	IBOutlet UINavigationBar *aboutViewNavbar;

}

- (void)refreshOwnerData;
- (void)toggleSwitch;

- (IBAction)dismiss:(id)sender;


@end
