//
//  HandshakeAppDelegate.h
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HandshakeViewController;

@interface HandshakeAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    HandshakeViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet HandshakeViewController *viewController;

@end

