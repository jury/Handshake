//
//  HSKFileBrowser.h
//  Handshake
//
//  Created by Kyle on 11/6/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MediaPlayer/MPMoviePlayerController.h"

#define kCellImageViewTag           1000
#define kCellLabelTag               1001
#define kCellIconTag				1002
#define kCellSizeTag				1003
#define kCellDateTag				1004


#define kLabelIndentedRect          CGRectMake(85.0, 12.0, 200.0, 20.0)
#define kLabelRect                  CGRectMake(60.0, 12.0, 225.0, 20.0)

#define kDateIndentedRect          CGRectMake(85.0, 30.0, 150.0, 20.0)
#define kDateRect                  CGRectMake(60.0, 30.0, 150.0, 20.0)

#define kIconIndet				   CGRectMake(35.0, 10.0, 45.0, 45.0)
#define kIconRect                  CGRectMake(10.0, 10.0, 45.0, 45.0)

#define kSizeLabel                 CGRectMake(150, 45.0, 125, 10.0)


@interface HSKFileBrowser : UIViewController <UITableViewDelegate>
{
	IBOutlet UITableView *fileBrowserTableView;

	IBOutlet UIToolbar *bottomTabBar;
	IBOutlet UILabel *diskSpaceLabel;
	IBOutlet UIButton *sendButton;
	IBOutlet UIButton *deleteButton;

	NSMutableArray *selectedArray;
	BOOL inMassSelectMode;
	
	UIImage *selectedImage;
	UIImage *unselectedImage;
	
	int numObjectsSelected;
	
	NSArray *rootDocumentPath;
    NSString *workingDirectory;
	NSMutableArray *fileArray;
	MPMoviePlayerController *moviePlayer;
}

-(id)initWithDirectory:(NSString *)directory;
-(void) moviePlayBackDidFinish;
-(void) movieDidFinishLoading;
-(void) selectMass;
- (void)populateSelectedArray;

- (IBAction)massSend:(id)sender;
- (IBAction)massDelete:(id)sender;


@property(nonatomic, retain) NSArray *rootDocumentPath;
@property(nonatomic, retain) NSString *workingDirectory;
@property(nonatomic, retain) NSMutableArray *fileArray;
@property(nonatomic, retain) NSMutableArray *selectedArray;
@property(nonatomic, retain) UIImage *selectedImage;
@property(nonatomic, retain) UIImage *unselectedImage;


@end


