//
//  HSKViewController.h
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>


@interface HSKMainViewController : UIViewController <UIActionSheetDelegate, ABPeoplePickerNavigationControllerDelegate, UITableViewDelegate >
{
	id ownerCard;
	IBOutlet UITableView *mainTable;
}

- (void)sendMyVcard;

-(void)verifyOwnerCard;

@end

