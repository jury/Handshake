//
//  HSKPicturePreviewViewController.h
//  Handshake
//
//  Created by Ian Baird on 10/5/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class HSKPicturePreviewViewController;

@protocol HSKPicturePreviewViewControllerDelegate

- (void)picturePreviewierDidClose:(HSKPicturePreviewViewController *)sender;

@end

@interface HSKPicturePreviewViewController : UIViewController <UIActionSheetDelegate>
{
    IBOutlet UIImageView *pictureImageView;
    
    id <HSKPicturePreviewViewControllerDelegate> delegate;
}

@property(nonatomic, retain) UIImageView *pictureImageView;
@property(nonatomic, assign) id <HSKPicturePreviewViewControllerDelegate> delegate;

@end
