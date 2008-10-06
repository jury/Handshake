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
#import "NSData+Base64Additions.h"

@class HSKFlipsideController;

@interface HSKMainViewController : UIViewController <UIActionSheetDelegate,
													ABPeoplePickerNavigationControllerDelegate,
													UITableViewDelegate,
													UIImagePickerControllerDelegate,
													UINavigationControllerDelegate, 
													RPSBrowserViewControllerDelegate, 
													RPSNetworkDelegate, 
													ABUnknownPersonViewControllerDelegate>
{
	ABRecordID ownerRecord;
	ABRecordID otherRecord;

	BOOL primaryCardSelecting;   //we need some kind of flag to know if we are selecting a primary user or another vcard
	IBOutlet UITableView *mainTable;
	IBOutlet UIView *flipView;
    IBOutlet UIView *frontView;
    
    IBOutlet UIView *overlayView;
    IBOutlet UIActivityIndicatorView *overlayActivityIndicatorView;
	
	IBOutlet HSKFlipsideController *flipsideController;
	
	NSString *dataToSend;
	
	id lastMessage;
	
	BOOL userBusy;
}


- (void)sendMyVcard;
- (void)sendOtherVcard;
- (void)sendPicture:(UIImage *)pict;
-(void)recievedVCard:(NSString *)string;
-(void)recievedPict:(NSString *)string;
-(void)verifyOwnerCard;
-(void)ownerFound;
-(IBAction)flipView;
-(void)flipBack;

@end

