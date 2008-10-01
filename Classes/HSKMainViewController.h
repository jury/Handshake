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


@interface HSKMainViewController : UIViewController <UIActionSheetDelegate, ABPeoplePickerNavigationControllerDelegate, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ABUnknownPersonViewControllerDelegate  >
{
	ABRecordID ownerRecord;
	ABRecordID otherRecord;

	BOOL primaryCardSelecting;   //we need some kind of flag to know if we are selecting a primary user or another vcard
	IBOutlet UITableView *mainTable;
}

- (void)sendMyVcard;
- (void)sendOtherVcard;
-(void)recievedCard:(NSString *)string;
-(void)verifyOwnerCard;

@end

