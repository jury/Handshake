//
//  HSKFileBrowser.h
//  Handshake
//
//  Created by Kyle on 11/6/08.
//  Copyright (c) 2009, Skorpiostech, Inc.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//      * Neither the name of the Skorpiostech, Inc. nor the
//        names of its contributors may be used to endorse or promote products
//        derived from this software without specific prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY SKORPIOSTECH, INC. ''AS IS'' AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL SKORPIOSTECH, INC. BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.//

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
	IBOutlet UIToolbar *freeSpaceTabBar;
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

+(NSNumber *) freeSpaceInBytes;

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


