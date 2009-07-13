//
//  HSKFileViewerViewController.m
//  Handshake
//
//  Created by Kyle on 11/6/08.
//  Copyright (c) 2009, Skorpiostech, Inc.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//      * Neither the name of the Skorpiostech, Inc. nor the
//        names of its contributors may be used to endorse or promote products
//        derived from this software without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY SKORPIOSTECH, INC. ''AS IS'' AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL SKORPIOSTECH, INC. BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.//

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
	browserWebView.scalesPageToFit = YES;
	[browserWebView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString:self.workingDirectory]]];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
	self.workingDirectory = nil;
	
	[browserWebView stopLoading];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
														message:NSLocalizedString(@"Your device has run out of memory and can not load this document fully.", @"Out of memory web view warning") 
													   delegate:nil 
											  cancelButtonTitle:nil 
											  otherButtonTitles:NSLocalizedString(@"Okay", @"Out of memory warning action"),nil];
	[alertView show];
	[alertView release];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	loadingOverlayView.hidden = TRUE;
	[loadingSpinner stopAnimating];
	loadingLabel.hidden = TRUE;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	loadingOverlayView.hidden = TRUE;
	[loadingSpinner stopAnimating];
	loadingLabel.hidden = TRUE;
}

- (void)dealloc 
{
	[browserWebView release];
	self.workingDirectory = nil;
    [super dealloc];
}


@end
