//
//  HSKPicturePreviewViewController.m
//  Handshake
//
//  Created by Ian Baird on 10/5/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKPicturePreviewViewController.h"


@implementation HSKPicturePreviewViewController

@synthesize pictureImageView, delegate;

// Override initWithNibName:bundle: to load the view using a nib file then perform additional customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
    {
        self.title = NSLocalizedString(@"Picture Preview", @"Picture Preview View title");
    }
    return self;
}

- (void)dealloc 
{
    self.pictureImageView = nil;
    
    [super dealloc];
}

- (void)dismissModal:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
    
    [delegate picturePreviewierDidClose:self];
}

- (void)saveImage:(id)sender
{
    UIImageWriteToSavedPhotosAlbum(self.pictureImageView.image, nil, nil, nil);
    
    [self dismissModal:nil];
}

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem =  [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveImage:)] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModal:)] autorelease];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

@end
