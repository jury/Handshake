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
	UIBarButtonItem *doneButton; 
	
	IBOutlet UIView *aboutView;
}

- (void)refreshOwnerData;
- (void)toggleSwitch;
- (void)removeAboutScreen;

- (IBAction)dfsw:(id)sender;
- (IBAction)skorp:(id)sender;
- (IBAction)link:(id)sender;

@end
