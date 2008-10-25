//
//  HSKImageRounding.h
//  Handshake
//
//  Created by Kyle on 10/25/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface ImageManipulator : NSObject {
}
+(UIImage *)makeRoundCornerImage:(UIImage*)img :(int) cornerWidth :(int) cornerHeight;
@end