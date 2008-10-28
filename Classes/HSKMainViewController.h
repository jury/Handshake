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
#import "HSKSMSModalViewController.h"
#import "HSKSoundEffect.h"


@class HSKFlipsideController;
@class HSKCustomAdController;
@class HSKSoundEffect;

@interface HSKMainViewController : UIViewController <UIActionSheetDelegate,
													ABPeoplePickerNavigationControllerDelegate,
													UITableViewDelegate,
													UIImagePickerControllerDelegate,
													UINavigationControllerDelegate, 
													RPSBrowserViewControllerDelegate, 
													RPSNetworkDelegate, 
													ABUnknownPersonViewControllerDelegate,
                                                    HSKSMSModalViewControllerDelegate>
{
	ABRecordID ownerRecord;
	ABRecordID otherRecord;

	BOOL primaryCardSelecting;   //we need some kind of flag to know if we are selecting a primary user or another vcard
	IBOutlet UITableView *mainTable;
	IBOutlet UIView *flipView;
    IBOutlet UIView *frontView;
    
    IBOutlet UIView *overlayView;
    IBOutlet UIActivityIndicatorView *overlayActivityIndicatorView;
    IBOutlet UILabel *overlayLabel;
    IBOutlet UIButton *overlayRetryButton;
    
    IBOutlet UIActivityIndicatorView *messageSendIndicatorView;
    IBOutlet UILabel *messageSendLabel;
	IBOutlet UIImageView *messageSendBackground;
    
	IBOutlet HSKFlipsideController *flipsideController;
	
	NSDictionary* objectToSend;	
	NSMutableArray *messageArray;
	
	id lastMessage;
	id lastPeer;
	NSString *lastPeerHandle;
	
	BOOL userBusy;
    BOOL isFlipped;
    BOOL bounce;
	BOOL MessageIsFromQueue;
    BOOL isShowingOverlayView;
	
	UIImage *avatarImage;
	
	NSDate *lastSoundPlayed;
	
	HSKSoundEffect *send;
	HSKSoundEffect *receive;
	
    UIButton *frontButton;
    
    NSTimer *overlayTimer;
    
    IBOutlet UIViewController *adController;
    
    IBOutlet HSKCustomAdController *customAdController;
    
    
}

@property(nonatomic, retain) HSKCustomAdController *customAdController;

- (void)sendMyVcard:(BOOL)isBounce;
- (void)sendOtherVcard:(id)sender;
-(void)recievedVCard: (NSDictionary *)vCardDictionary;
-(void)recievedPict:(NSDictionary *)pictDictionary;
-(void)verifyOwnerCard;
-(void)ownerFound;

-(void)playReceived;
-(void)playSend;

-(IBAction)flipView;
-(void)flipBack;
- (void)checkQueueForMessages;
-(void)formatForVcard:(NSDictionary *)dictionary;
- (IBAction)retryConnection:(id)sender;

@end

