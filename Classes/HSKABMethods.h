//
//  HSKABMethods.h
//  Handshake
//
//  Created by Kyle on 11/2/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Beacon.h"
#import "HSKUnknownPersonViewController.h"
#import "NSData+Base64Additions.h"
#import "HSKNavigationController.h"
#import "HSKMainViewController.h"

@class HSKMainViewController;

@interface HSKABMethods : NSObject
{
	HSKMainViewController *viewController;	

}

+ (id)sharedInstance;
-(NSString *)formatForVcard:(NSDictionary *)VcardDictionary;
-(ABRecordRef)recievedVCard: (NSDictionary *)vCardDictionary: (NSString *) lastPeerHandle;
-(NSDictionary *)sendMyVcard: (BOOL) isBounce : (ABRecordID) ownerRecord;
@end
