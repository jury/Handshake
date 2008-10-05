//
//  flipsideController.h
//  Handshake
//
//  Created by Kyle on 10/5/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>


@interface HSKFlipsideController : NSObject <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
{
	IBOutlet UITableView *flipsideTable;

	NSString *userName;
	BOOL allowImageEdit;
	UIImage *avatar;
	
}

@end
