//
//  HSKUnknownPersonViewController.m
//  Handshake
//
//  Created by Ian Baird on 10/5/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKUnknownPersonViewController.h"


@implementation HSKUnknownPersonViewController

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModals:)] autorelease];
}

- (void)dismissModals:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
    // XXX: fixing apple's stupidity, these are non-retained properties.
    if (self.addressBook)
    {
        CFRelease(self.addressBook);
    }
    self.addressBook = nil;
    if (self.displayedPerson)
    {
        CFRelease(self.displayedPerson);
    }
    self.displayedPerson = nil;
    
    [super dealloc];
}


@end
