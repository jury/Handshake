//
//  HSKFileViewerViewController.m
//  Handshake
//
//  Created by Kyle on 11/6/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKFileViewerViewController.h"

@implementation HSKFileViewerViewController
@synthesize workingDirectory;


-(id) initWithFile: (NSString *)filePath
{
	self = [super initWithNibName: @"fileViewer" bundle:nil];
	
	self.workingDirectory = filePath;
	
	self.navigationItem.title = [self.workingDirectory lastPathComponent];

	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(sendObject)] autorelease];


	return self;
}

-(void) sendObject
{
	
}


/*
// Override initWithNibName:bundle: to load the view using a nib file then perform additional customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	NSLog(@"Starting to Load");

	
	browserWebView.scalesPageToFit = YES;
	[browserWebView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString:self.workingDirectory]]];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning 
{
	
	[browserWebView stopLoading];
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
														message:NSLocalizedString(@"Your device has run out of memory and can not load this document fully.", @"Out of memory web view warning") 
													   delegate:nil 
											  cancelButtonTitle:nil 
											  otherButtonTitles:NSLocalizedString(@"Okay", @"Out of memory warning action"),nil];
	[alertView show];
	[alertView release];
	
	
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	NSLog(@"Finished Loading");
	
}

- (void)dealloc 
{
	self.workingDirectory = nil;
    [super dealloc];
}


@end
