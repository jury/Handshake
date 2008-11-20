//
//  HSKDataServer.h
//  Handshake
//
//  Created by Ian Baird on 11/4/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CTCPSocketListener.h"

@interface HSKBypassServer : NSObject <CTCPSocketListenerDelegate>
{
    CTCPSocketListener *socketListener;
}

@property (nonatomic, retain) CTCPSocketListener *socketListener;

- (void)createDefaultSocketListener;

@end
