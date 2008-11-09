//
//  HSKFileTextViewController.m
//  Handshake
//
//  Created by Kyle on 11/6/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKFileTextViewController.h"


@implementation HSKFileTextViewController


@synthesize workingDirectory;

-(id) initWithFile: (NSString *)filePath
{
	self = [super initWithNibName: @"textFileViewer" bundle:nil];
	self.navigationItem.title = [filePath lastPathComponent];
	
	self.workingDirectory = filePath;
	return self;
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
- (void)viewDidLoad {
    [super viewDidLoad];
	
	
	[textView setText: [NSString stringWithContentsOfFile: self.workingDirectory]];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}


@end
