//
//  HSKViewController.h
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddressBookUI/ABPeoplePickerNavigationController.h"


@interface HSKMainViewController : UIViewController <UIActionSheetDelegate, ABPeoplePickerNavigationControllerDelegate>
{
	ABRecordRef owner;
}

- (IBAction)sendMyVcard;
- (IBAction)sendOtherVcard;
- (IBAction)sendPicture;


@end

