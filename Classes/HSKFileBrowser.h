//
//  HSKFileBrowser.h
//  Handshake
//
//  Created by Kyle on 11/6/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MediaPlayer/MPMoviePlayerController.h"


@interface HSKFileBrowser : UIViewController <UITableViewDelegate>
{
	IBOutlet UITableView *fileBrowserTableView;
	
	NSArray *rootDocumentPath;
    NSString *workingDirectory;
	NSMutableArray *fileArray;
	MPMoviePlayerController *moviePlayer;
}

-(id)initWithDirectory:(NSString *)directory;
-(void) moviePlayBackDidFinish;
-(void) movieDidFinishLoading;

@property(nonatomic, retain) NSArray *rootDocumentPath;
@property(nonatomic, retain) NSString *workingDirectory;
@property(nonatomic, retain) NSMutableArray *fileArray;


@end


