//
//  HSKAboutViewController.m
//  Handshake
//
//  Created by Kyle on 10/16/08.
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

#import "HSKAboutViewController.h"
#import "Beacon.h"
#import "HSKBeacons.h"

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
	[[Beacon shared] startSubBeaconWithName:kHSKBeaconDFSWLogoTouch timeSession:NO];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.dragonforged.com"]];
	
}
- (IBAction)skorp:(id)sender
{
	[[Beacon shared] startSubBeaconWithName:kHSKBeaconSkorpiostechLogoTouch timeSession:NO];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.skorpiostech.com/"]];
	
}
- (IBAction)link:(id)sender
{
	[[Beacon shared] startSubBeaconWithName:kHSKBeaconGetHandshakeURLTouch timeSession:NO];
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
