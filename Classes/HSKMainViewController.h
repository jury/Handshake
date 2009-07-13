//
//  HSKViewController.h
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright (c) 2009, Skorpiostech, Inc.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//      * Neither the name of the Skorpiostech, Inc. nor the
//        names of its contributors may be used to endorse or promote products
//        derived from this software without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY SKORPIOSTECH, INC. ''AS IS'' AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL SKORPIOSTECH, INC. BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.//

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

//--

enum {
    kHSKOwnerDetectMessageTag,
    kHSKReceivedVcardMessageNoPopAllTag,
    kHSKReceivedVcardMessagePopAllTag,
    kHSKReceivedVcardBounceMessageNoPopAllTag,
    kHSKReceivedVcardBounceMessagePopAllTag,
    kHSKReceivedImageMessageNoPopAllTag,
    kHSKReceivedImageMessagePopAllTag,
    kHSKReceivedReadyToSendMessageTag
};
typedef NSUInteger HSKAlertMessageTag;

//--

@class HSKFlipsideController;
@class HSKCustomAdController;
@class HSKSoundEffect;
@class HSKMessage;

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
	
	BOOL isUIBusy;
    BOOL isFlipped;
    BOOL bounce;
    BOOL isShowingOverlayView;
	
	UIImage *avatarImage;
	
	ABRecordID recordToSend;
	
	NSDate *lastSoundPlayed;
	
	HSKSoundEffect *send;
	HSKSoundEffect *receive;
    
    HSKMessage *messageToSend;
    HSKMessage *receivedMessage;
	
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

