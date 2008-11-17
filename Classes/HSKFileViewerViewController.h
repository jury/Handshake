//
//  HSKFileViewerViewController.h
//  Handshake
//
//  Created by Kyle on 11/6/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HSKFileViewerViewController : UIViewController <UIWebViewDelegate>
{
	IBOutlet UIWebView *browserWebView;
	
	IBOutlet UIImageView *loadingOverlayView;
	IBOutlet UIActivityIndicatorView *loadingSpinner;
	IBOutlet UILabel *loadingLabel;
	
	NSString *workingDirectory;
	
}

-(id)initWithFile:(NSString *)filePath;
-(void) sendObject;


@property(nonatomic, retain) NSString *workingDirectory;


@end
