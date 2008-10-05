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
#import "RPSBrowserViewController.h"
#import "RPSNetwork.h"
#import "RPSNetworkPeer.h"
#import "RPSNetworkPeersList.h"


@interface HSKMainViewController : UIViewController <UIActionSheetDelegate,
													ABPeoplePickerNavigationControllerDelegate,
													UITableViewDelegate,
													UIImagePickerControllerDelegate,
													UINavigationControllerDelegate, 
													RPSBrowserViewControllerDelegate, 
													RPSNetworkDelegate, 
													ABUnknownPersonViewControllerDelegate,
													ABPersonViewControllerDelegate,
													ABNewPersonViewControllerDelegate>
{
	ABRecordID ownerRecord;
	ABRecordID otherRecord;

	BOOL primaryCardSelecting;   //we need some kind of flag to know if we are selecting a primary user or another vcard
	IBOutlet UITableView *mainTable;
	NSString *dataToSend;
}


- (void)sendMyVcard;
- (void)sendOtherVcard;
-(void)recievedCard:(NSString *)string;
-(void)verifyOwnerCard;
-(void)ownerFound;

@end

