//
//  HSKPicturePreviewViewController.m
//  Handshake
//
//  Created by Ian Baird on 10/5/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKPicturePreviewViewController.h"


@implementation HSKPicturePreviewViewController

@synthesize pictureImageView;

// Override initWithNibName:bundle: to load the view using a nib file then perform additional customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
    {
        self.title = @"Picture Preview";
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
}

- (IBAction)addAction:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Save Picture",nil];
    [actionSheet showFromToolbar:toolbar];
    [actionSheet release];
}

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModal:)] autorelease];
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


#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        UIImageWriteToSavedPhotosAlbum(self.pictureImageView.image, nil, nil, nil);
        
        [self dismissModal:nil];
    }
}


@end
