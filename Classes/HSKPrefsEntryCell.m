//
//  HSKPrefsEntryCell.m
//  Handshake
//
//  Created by Ian Baird on 10/28/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKPrefsEntryCell.h"


@implementation HSKPrefsEntryCell

@synthesize labelLabel, entryField;

- (void)dealloc 
{
    self.labelLabel = nil;
    self.entryField = nil;
    
    [super dealloc];
}


@end
