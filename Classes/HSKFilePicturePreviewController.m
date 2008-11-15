//
//  HSKFilePicturePreviewController.m
//  Handshake
//
//  Created by Kyle on 11/6/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKFilePicturePreviewController.h"


@implementation HSKFilePicturePreviewController

@synthesize workingDirectory;

-(id) initWithFile: (NSString *)filePath
{
	self = [super initWithNibName: @"FilePicturePreview" bundle:nil];
	self.navigationItem.title = [filePath lastPathComponent];
	
	self.workingDirectory = filePath;
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(sendObject)] autorelease];

	
	return self;
}

-(void) sendObject
{
	
}

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	pictureImageView.userInteractionEnabled = TRUE;
	[pictureImageView setImage: [UIImage imageWithData: [NSData dataWithContentsOfFile: self.workingDirectory]]];
	
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
	self.workingDirectory = nil;

    [super dealloc];
}


@end
