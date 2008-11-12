//
//  HSKFileAdditonalDetailsView.h
//  Handshake
//
//  Created by Kyle on 11/11/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HSKFileAdditonalDetailsView : UITableViewController <UITextFieldDelegate>
{
	NSString *workingDirectory;
	
	IBOutlet UITableView *additionalDetailsTable;
}


-(id) initWithFile: (NSString *)filePath;
-(void) sendObject;

@property(nonatomic, retain) NSString *workingDirectory;

@end
