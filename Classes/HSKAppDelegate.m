//
//  HSKAppDelegate.m
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//



#import "HSKAppDelegate.h"
#import "HSKMainViewController.h"

@implementation HSKAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application 
{        
    [window setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
    
    // Verify that the owner information is properly stored
    [(HSKMainViewController *)viewController.topViewController verifyOwnerCard];
}


- (void)dealloc 
{
    [viewController release];
    [window release];
    [super dealloc];
}


@end
