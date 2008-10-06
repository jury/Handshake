//
//  HSKPicturePreviewViewController.h
//  Handshake
//
//  Created by Ian Baird on 10/5/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HSKPicturePreviewViewController : UIViewController <UIActionSheetDelegate>
{
    IBOutlet UIImageView *pictureImageView;
    IBOutlet UIToolbar *toolbar;
}

@property(nonatomic, retain) UIImageView *pictureImageView;

- (IBAction)addAction:(id)sender;

@end
