//
//  HSKAboutViewController.m
//  Handshake
//
//  Created by Kyle on 10/16/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKAboutViewController.h"
#import "Beacon.h"


@implementation HSKAboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    aboutLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Version %@", @"About view - version format string"), appVersion];
    
    NSString *appIconFN = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFile"];
    appIconImageView.image = [UIImage imageNamed:appIconFN];
}

- (IBAction)dfsw:(id)sender
{
	[[Beacon shared] startSubBeaconWithName:@"dfsw" timeSession:NO];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.dragonforged.com"]];
	
}
- (IBAction)skorp:(id)sender
{
	[[Beacon shared] startSubBeaconWithName:@"skorp" timeSession:NO];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.skorpiostech.com/"]];
	
}
- (IBAction)link:(id)sender
{
	[[Beacon shared] startSubBeaconWithName:@"gethandshake" timeSession:NO];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.gethandshake.com"]];
	
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

/*
// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


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
