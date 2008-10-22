//
//  HSKAppDelegate.m
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//



#import "HSKAppDelegate.h"
#import "HSKMainViewController.h"
#import "Beacon.h"


@implementation HSKAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application 
{        
	
	NSString *applicationCode = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"PMapplicationkey"];
	
	NSLog(@"PM application code: %@", applicationCode);
	
	[Beacon initAndStartBeaconWithApplicationCode:applicationCode useCoreLocation:NO];
	
    [window setBackgroundColor:[UIColor viewFlipsideBackgroundColor]];
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
    
    // Verify that the owner information is properly stored (do this after the runloop has started)
    // (this is guarded with a timer to avoid timeout on launch)
    [(HSKMainViewController *)viewController.topViewController performSelector:@selector(verifyOwnerCard) withObject:nil afterDelay:0.0];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[[Beacon shared] endBeacon];
}

- (void)dealloc 
{
    [viewController release];
    [window release];
    [super dealloc];
}


@end
