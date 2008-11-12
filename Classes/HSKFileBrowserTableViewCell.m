//
//  HSKFileBrowserTableViewCell.m
//  Handshake
//
//  Created by Kyle on 11/11/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKFileBrowserTableViewCell.h"


@implementation HSKFileBrowserTableViewCell

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc 
{
    [super dealloc];
}


@end
