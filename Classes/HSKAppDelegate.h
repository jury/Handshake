//
//  HSKAppDelegate.h
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HSKMainViewController;

@interface HSKAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    HSKMainViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet HSKMainViewController *viewController;

@end

