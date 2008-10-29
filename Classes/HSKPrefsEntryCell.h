//
//  HSKPrefsEntryCell.h
//  Handshake
//
//  Created by Ian Baird on 10/28/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HSKPrefsEntryCell : UITableViewCell 
{
    IBOutlet UILabel *labelLabel;
    IBOutlet UITextField *entryField;
}
@property(nonatomic, retain) UILabel *labelLabel;
@property(nonatomic, retain) UITextField *entryField;

@end
