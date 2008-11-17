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
#import "RPSNetworkPeer.h"
#import "RPSNetworkPeersList.h"
#import "NSData+Base64Additions.h"
#import "HSKSMSModalViewController.h"
#import "HSKEmailModalViewController.h"
#import "HSKSoundEffect.h"
#import "SKPSMTPMessage.h"
#import "HSKPicturePreviewViewController.h"
#import "HSKMessageBus.h"


@class HSKFlipsideController;
@class HSKCustomAdController;
@class HSKSoundEffect;

@interface HSKMainViewController : UIViewController <UIActionSheetDelegate,
													ABPeoplePickerNavigationControllerDelegate,
													UITableViewDelegate,
													UIImagePickerControllerDelegate,
													UINavigationControllerDelegate, 
													RPSBrowserViewControllerDelegate, 
													ABUnknownPersonViewControllerDelegate,
                                                    HSKSMSModalViewControllerDelegate,
                                                    HSKEmailModalViewControllerDelegate,
                                                    SKPSMTPMessageDelegate,
                                                    HSKPicturePreviewViewControllerDelegate,
                                                    HSKMessageBusDelegate>
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
	
	BOOL userBusy;
    BOOL isFlipped;
    BOOL bounce;
	BOOL MessageIsFromQueue;
    BOOL isShowingOverlayView;
	
	UIImage *avatarImage;
	
	ABRecordID recordToSend;
	
	NSDate *lastSoundPlayed;
	
	HSKSoundEffect *send;
	HSKSoundEffect *receive;
	
    UIButton *frontButton;
    
    NSTimer *overlayTimer;
    
    IBOutlet UIViewController *adController;
    
    IBOutlet HSKCustomAdController *customAdController;
}

@property(nonatomic, retain) HSKCustomAdController *customAdController;

-(void) verifyOwnerCard;
-(void) ownerFound;
-(void) sendVcard;
-(void) recievedVcard;

- (IBAction)retryConnection:(id)sender;
- (IBAction)flipView;

@end

