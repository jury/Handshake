//
//  HSKUnknownPersonController.m
//  Handshake
//
//  Created by Ian Baird on 10/4/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKUnknownPersonController.h"

@interface UIView (HSKAdditions)

- (void)dumpSubviews;

@end

@implementation UIView (HSKAdditions)

- (void)dumpSubviews
{
    NSLog(@"found view of type %@", [self class]);
    
    for (UIView *view in self.subviews)
    {
        [view dumpSubviews];
    }
}

@end


@implementation HSKUnknownPersonController

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
    
    [self.view dumpSubviews];
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
