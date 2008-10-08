//
//  HSKNavigationController.m
//  Handshake
//
//  Created by Ian Baird on 10/7/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKNavigationController.h"
#import "HSKMainViewController.h"

NSString *HSKNavigationControllerDidDismissModal = @"HSKNavigationControllerDidDismissModal";

@implementation HSKNavigationController

- (void)dismissModalViewControllerAnimated:(BOOL)animated
{
    [super dismissModalViewControllerAnimated:animated];
    
    if ([self.parentViewController isKindOfClass:[UINavigationController class]])
    {        
        [[NSNotificationCenter defaultCenter] postNotificationName:HSKNavigationControllerDidDismissModal object:self userInfo:nil];
    }
}


@end
