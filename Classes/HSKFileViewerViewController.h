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
	NSString *workingDirectory;
	
}

-(id)initWithFile:(NSString *)filePath;

@property(nonatomic, retain) NSString *workingDirectory;


@end
