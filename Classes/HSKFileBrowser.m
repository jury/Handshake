//
//  HSKFileBrowser.m
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

#import "HSKFileBrowser.h"
#import "HSKFileViewerViewController.h"
#import "HSKFilePicturePreviewController.h"
#import "HSKFileTextViewController.h"
#import "HSKFileAdditonalDetailsView.h"

@implementation HSKFileBrowser

@synthesize rootDocumentPath, workingDirectory, fileArray, selectedArray, selectedImage, unselectedImage;

+(NSNumber *) freeSpaceInBytes;
{		
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);	
	
	return [[[NSFileManager defaultManager] fileSystemAttributesAtPath: [paths objectAtIndex:0]] objectForKey: @"NSFileSystemFreeSize"];
}

-(id)initWithDirectory:(NSString *)directory
{
	self = [super initWithNibName:@"FileBrowserViewController" bundle:nil];
	self.workingDirectory = directory;
	
	//make some dummy objects
	for(int x = 0; x < 6; x++)
		[[NSFileManager defaultManager] createDirectoryAtPath: [NSString stringWithFormat:@"%@/Folder #%i", self.workingDirectory, x] attributes:nil];
	
	return self;
}

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
	diskSpaceLabel.hidden = FALSE;
	sendButton.enabled = FALSE;
	deleteButton.enabled = FALSE;
	inMassSelectMode = FALSE;
		
    [super viewDidLoad];
	
	self.fileArray = [NSMutableArray arrayWithArray: [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.workingDirectory error:NULL]];
	self.navigationItem.title = [self.workingDirectory lastPathComponent];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select", @"Button to select multiple files")  style:UIBarButtonItemStylePlain target:self action:@selector(selectMass)] autorelease];
	
	//clear out the selected database
	[self populateSelectedArray];
	self.selectedImage = [UIImage imageNamed:@"selected.png"];
	self.unselectedImage = [UIImage imageNamed:@"unselected.png"];
	
	NSNumber *freeSpaceBytes =  [[[NSFileManager defaultManager] fileSystemAttributesAtPath: self.workingDirectory] objectForKey: @"NSFileSystemFreeSize"]; 
	
	if([freeSpaceBytes doubleValue] < 1048576)
		diskSpaceLabel.text = [NSString stringWithFormat: NSLocalizedString(@"%0.0f KBs Available", @"Free space in kilobytes") , [freeSpaceBytes doubleValue]/1024];
	else if ([freeSpaceBytes doubleValue] < 1073741824)
		diskSpaceLabel.text = [NSString stringWithFormat: NSLocalizedString(@"%0.2f MBs Available", @"Free space in megabytes") , [freeSpaceBytes doubleValue]/1024/1024];
	else
		diskSpaceLabel.text = [NSString stringWithFormat: NSLocalizedString(@"%0.2f GBs Available", @"Free space in gigabytes") , [freeSpaceBytes doubleValue]/1024/1024/1024];
	
	sendButton.frame = CGRectMake(0.0, 0.0, 95, 30);
	deleteButton.frame = CGRectMake(0.0, 00.0, 95, 30);
	
	sendButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	sendButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	
	[sendButton setBackgroundImage: [[UIImage imageNamed: @"greenButton.png"] stretchableImageWithLeftCapWidth:7.0 topCapHeight:0.0] forState:UIControlStateNormal];
	[deleteButton setBackgroundImage: [[UIImage imageNamed: @"redButton.png"] stretchableImageWithLeftCapWidth:7.0 topCapHeight:0.0] forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self.fileArray removeAllObjects];
	self.fileArray = [NSMutableArray arrayWithArray: [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workingDirectory error:NULL]];
	[fileBrowserTableView reloadData];
	[super viewDidAppear:animated];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [fileArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{	
	static NSString *MyIdentifier = @"MyIdentifier";
	
	BOOL isDirectory = FALSE;
	[[NSFileManager defaultManager] fileExistsAtPath:[self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] isDirectory:&isDirectory];

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) 
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
		
		[cell setSelectionStyle: UITableViewCellSelectionStyleNone];
		
		UILabel *dateLabel = [[UILabel alloc] initWithFrame:kDateRect];
		dateLabel.tag = kCellDateTag;
		[dateLabel setFont: [UIFont systemFontOfSize: 12]];
		[dateLabel setTextColor: [UIColor grayColor]];
		[cell.contentView addSubview:dateLabel];
		[dateLabel release];
		
		UILabel *label = [[UILabel alloc] initWithFrame:kLabelRect];
		label.tag = kCellLabelTag;
		[cell.contentView addSubview:label];
		[label release];
		
		UILabel *sizeLabel = [[UILabel alloc] initWithFrame:kSizeLabel];
		sizeLabel.tag = kCellSizeTag;
		[sizeLabel setFont: [UIFont systemFontOfSize: 10]];
		[sizeLabel setTextAlignment: UITextAlignmentRight];
		[sizeLabel setTextColor: [UIColor grayColor]];
		[cell.contentView addSubview:sizeLabel];
		[sizeLabel release];
		
		UIImageView *imageView = [[UIImageView alloc] initWithImage:unselectedImage];
		imageView.frame = CGRectMake(5.0, 22.0, 23.0, 23.0);
		[cell.contentView addSubview:imageView];
		imageView.hidden = !inMassSelectMode;
		imageView.tag = kCellImageViewTag;
		[imageView release];
		
		UIImageView *iconView = [[UIImageView alloc] initWithImage: nil];
		iconView.frame = kIconRect;
		[cell.contentView addSubview:iconView];
		iconView.tag = kCellIconTag;
		[iconView release];
	}
	
	[UIView beginAnimations:@"cell shift" context:nil];
	
	UILabel *label = (UILabel *)[cell.contentView viewWithTag:kCellLabelTag];
	label.text = [self.fileArray objectAtIndex: [indexPath row]];
	label.frame = (inMassSelectMode) ? kLabelIndentedRect : kLabelRect;
	label.opaque = NO;
	
	UIImageView *iconView = (UIImageView *)[cell.contentView viewWithTag:kCellIconTag];
	iconView.frame = (inMassSelectMode) ? kIconIndet : kIconRect;
	
	NSString *fileType = [[[self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] pathExtension] lowercaseString];
	fileType = [fileType stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	fileType = [fileType stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	if([fileType isEqualToString:@"xls"]|| [fileType isEqualToString:@"xlsx"])
		iconView.image = [UIImage imageNamed: @"Excel.png"];
	else if([fileType isEqualToString:@"doc"] || [fileType isEqualToString:@"docx"])
		iconView.image = [UIImage imageNamed: @"Word.png"];
	else if([fileType isEqualToString:@"ppt"] || [fileType isEqualToString:@"pptx"])
		iconView.image = [UIImage imageNamed: @"Powerpoint.png"];
	else if([fileType isEqualToString:@"pages"])
		iconView.image = [UIImage imageNamed: @"Pages.png"];
	else if([fileType isEqualToString:@"numbers"])
		iconView.image = [UIImage imageNamed: @"Numbers.png"];
	else if([fileType isEqualToString:@"keynote"])
		iconView.image = [UIImage imageNamed: @"Keynote.png"];
	else if([fileType isEqualToString:@"html"] || [fileType isEqualToString:@"htm"] || [fileType isEqualToString:@"php"] || [fileType isEqualToString:@"css"]||[fileType isEqualToString:@"mht"]|| [fileType isEqualToString:@"webarchive"])
		iconView.image = [UIImage imageNamed: @"HTML.png"];
	else if([fileType isEqualToString:@"txt"] || [fileType isEqualToString:@"log"] || [fileType isEqualToString:@"m"] || [fileType isEqualToString:@"h"] || [fileType isEqualToString:@"cpp"]|| [fileType isEqualToString:@"c"])
		iconView.image = [UIImage imageNamed: @"Text.png"];
	else if([fileType isEqualToString:@"jpg"] || [fileType isEqualToString:@"jpeg"] || [fileType isEqualToString:@"tiff"] || [fileType isEqualToString:@"gif"] || [fileType isEqualToString:@"png"]|| [fileType isEqualToString:@"pict"]|| [fileType isEqualToString:@"svg"])
		iconView.image = [UIImage imageNamed: @"Images.png"];
	else if([fileType isEqualToString:@"mov"] || [fileType isEqualToString:@"mpg"] || [fileType isEqualToString:@"mpeg"] || [fileType isEqualToString:@"mv4"] || [fileType isEqualToString:@"mp4"])
		iconView.image = [UIImage imageNamed: @"Movies.png"];
	else if([fileType isEqualToString:@"mp3"] || [fileType isEqualToString:@"caf"] || [fileType isEqualToString:@"aac"] || [fileType isEqualToString:@"aiff"]|| [fileType isEqualToString:@"wav"])
		iconView.image = [UIImage imageNamed: @"Music.png"];
	else if([fileType isEqualToString:@"pdf"])
		iconView.image = [UIImage imageNamed: @"PDF.png"];
	else if(isDirectory)
		iconView.image = [UIImage imageNamed: @"Folder.png"];
	else
		iconView.image = [UIImage imageNamed: @"Unknown.png"];
	
	

	
	UILabel *dateLabel = (UILabel *)[cell.contentView viewWithTag:kCellDateTag];
	NSDate *fileDate = [[[NSFileManager defaultManager] fileAttributesAtPath: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] traverseLink:NO] objectForKey: @"NSFileModificationDate"];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"MMM dd, yyyy HH:MM"];
	dateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate: fileDate]];
	dateLabel.frame = (inMassSelectMode) ? kDateIndentedRect : kDateRect;
	dateLabel.opaque = NO;
	
	[dateFormatter release];

	UILabel *sizeLabel;
	
	if(!isDirectory)
	{
		sizeLabel = (UILabel *)[cell.contentView viewWithTag:kCellSizeTag];
		NSNumber *fileSize = [[[NSFileManager defaultManager] fileAttributesAtPath: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] traverseLink:NO] objectForKey: @"NSFileSize"];
		
		if([fileSize doubleValue] < 1023)
			sizeLabel.text = [NSString stringWithFormat: @"%f Bytes", fileSize] ;
		else if([fileSize doubleValue] < 1048576)
		{
			double convertedSize = [fileSize doubleValue] / 1024;
			sizeLabel.text = [NSString stringWithFormat: @"%0.1f KBs", convertedSize] ;
		}
		else
		{
			double convertedSize = [fileSize doubleValue] / 1024 / 1024;
			sizeLabel.text = [NSString stringWithFormat: @"%0.1f MBs", convertedSize] ;
		}
		
		sizeLabel.opaque = NO;
	}
	
	else
	{
		sizeLabel = (UILabel *)[cell.contentView viewWithTag:kCellSizeTag];
		sizeLabel.text = [NSString stringWithFormat:  NSLocalizedString(@"%i Items", @"Number of items in a folder"), [[[NSFileManager defaultManager] contentsOfDirectoryAtPath: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] error: nil] count]];
		sizeLabel.opaque = NO;	
	}
	
	UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:kCellImageViewTag];
	NSNumber *selected = [selectedArray objectAtIndex:[indexPath row]];
	imageView.image = ([selected boolValue]) ? selectedImage : unselectedImage;
	imageView.hidden = !inMassSelectMode;
	
	if(inMassSelectMode)
	{
		
		cell.accessoryType = UITableViewCellAccessoryNone;
		[UIView commitAnimations];

		
		if(imageView.image == selectedImage)
		{
			UIImageView *backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed: @"cellBackground.png"]];
			cell.backgroundView = backgroundImage;
			sizeLabel.backgroundColor = [UIColor clearColor];
			dateLabel.backgroundColor = [UIColor clearColor];
			label.backgroundColor = [UIColor clearColor];

			
			[backgroundImage release];
		}
		else
		{
			cell.backgroundView = nil;
			sizeLabel.backgroundColor = [UIColor whiteColor];
			dateLabel.backgroundColor = [UIColor whiteColor];
			label.backgroundColor = [UIColor whiteColor];

		}
		
	}
	
	else
	{
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		[UIView commitAnimations];
		cell.backgroundView = nil;

	}
		

	
	// Configure the cell
	return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	HSKFileAdditonalDetailsView *additionalDetailView = [[HSKFileAdditonalDetailsView alloc] initWithFile: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]]];		
	[self.navigationController pushViewController:additionalDetailView animated: YES];
	[additionalDetailView release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	if (inMassSelectMode)
	{
		BOOL selected = [[selectedArray objectAtIndex:[indexPath row]] boolValue];
		[selectedArray replaceObjectAtIndex:[indexPath row] withObject:[NSNumber numberWithBool:!selected]];
		
		if(!selected)
			numObjectsSelected++;
		else
			numObjectsSelected--;
		
		[sendButton setTitle: [NSString stringWithFormat: NSLocalizedString(@"Send (%i)", @"Send Button"), numObjectsSelected] forState:UIControlStateNormal];
		[deleteButton setTitle: [NSString stringWithFormat: NSLocalizedString(@"Delete (%i)", @"Delete Button"), numObjectsSelected] forState:UIControlStateNormal];
		
		[sendButton setTitle: [NSString stringWithFormat: NSLocalizedString(@"Send (%i)", @"Send Button"), numObjectsSelected] forState:UIControlStateHighlighted];
		[deleteButton setTitle: [NSString stringWithFormat: NSLocalizedString(@"Delete (%i)", @"Delete Button"), numObjectsSelected] forState:UIControlStateHighlighted];

		
		if(numObjectsSelected > 0)
		{
			[sendButton setEnabled: YES];
			[deleteButton setEnabled: YES];
		}
		
		else
		{
			[sendButton setEnabled: NO];
			[deleteButton setEnabled: NO];	
			
			[sendButton setTitle: NSLocalizedString(@"Send", @"Send Button") forState:UIControlStateNormal];
			[deleteButton setTitle:  NSLocalizedString(@"Send", @"Delete Button") forState:UIControlStateNormal];
			
		}
		
		[tableView reloadData];
	}
	
	else
	{
		BOOL isDirectory = FALSE;

		[tableView deselectRowAtIndexPath: [tableView indexPathForSelectedRow] animated: NO];

		if([[NSFileManager defaultManager] fileExistsAtPath: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] isDirectory:&isDirectory])
		{
			if(isDirectory)
			{
				HSKFileBrowser *fileBrowserViewController = [[HSKFileBrowser alloc] initWithDirectory: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]]];		
				[self.navigationController pushViewController:fileBrowserViewController animated: YES];
				[fileBrowserViewController release];
			}
			
			//we have selected a file
			else
			{
				NSString *fileType = [[[self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] pathExtension] lowercaseString];
				fileType = [fileType stringByReplacingOccurrencesOfString:@"\n" withString:@""];
				fileType = [fileType stringByReplacingOccurrencesOfString:@" " withString:@""];
				
				//handle in webview
				if([fileType isEqualToString:@"html"] || 
				   [fileType isEqualToString:@"htm"] || 
				   [fileType isEqualToString:@"pdf"] || 
				   [fileType isEqualToString:@"xls"] || 
				   [fileType isEqualToString:@"doc"] ||
				   [fileType isEqualToString:@"ppt"] || 
				   [fileType isEqualToString:@"xlsx"] || 
				   [fileType isEqualToString:@"docx"] ||
				   [fileType isEqualToString:@"pptx"] ||
				   [fileType isEqualToString:@"zip"] || 
				   [fileType isEqualToString:@"txt"]|| 
				   [fileType isEqualToString:@"mht"]|| 
				   [fileType isEqualToString:@"webarchive"] || 
				   [fileType isEqualToString:@"php"] || 
				   [fileType isEqualToString:@"log"] || 
				   [fileType isEqualToString:@"m"] || 
				   [fileType isEqualToString:@"h"] || 
				   [fileType isEqualToString:@"cpp"] || 
				   [fileType isEqualToString:@"c"] || 
				   [fileType isEqualToString:@"css"])
				{
					HSKFileViewerViewController *fileBrowserViewController = [[HSKFileViewerViewController alloc] initWithFile: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]]];		
					[self.navigationController pushViewController:fileBrowserViewController animated: YES];
					[fileBrowserViewController release];
					
				}
				
				//handle with UIImage
				else if ([fileType isEqualToString:@"png"] || 
						 [fileType isEqualToString:@"jpg"] || 
						 [fileType isEqualToString:@"pict"] || 
						 [fileType isEqualToString:@"gif"] || 
						 [fileType isEqualToString:@"jpeg"] || 
						 [fileType isEqualToString:@"svg"] ||
						 [fileType isEqualToString:@"tif"] ||
						 [fileType isEqualToString:@"tiff"])
				{
				
					HSKFilePicturePreviewController *picPreviewController = [[HSKFilePicturePreviewController alloc] initWithFile:[self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]]];
					[self.navigationController pushViewController:picPreviewController animated: YES];
					[picPreviewController release];
				}
				
				//handle with movie player
				else if ([fileType isEqualToString:@"mov"] ||
						 [fileType isEqualToString:@"mp3"] ||
						 [fileType isEqualToString:@"mpg"] || 
						 [fileType isEqualToString:@"mpeg"] || 
						 [fileType isEqualToString:@"caf"] || 
						 [fileType isEqualToString:@"aiff"] || 
						 [fileType isEqualToString:@"wav"] ||
						 [fileType isEqualToString:@"m4v"] ||
						 [fileType isEqualToString:@"aac"] ||
						 [fileType isEqualToString:@"mp4"])
				{
					moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:  [NSURL fileURLWithPath: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]]]];
					moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
					moviePlayer.movieControlMode = MPMovieControlModeDefault;
					moviePlayer.backgroundColor = [UIColor blackColor];
					
				
					[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(movieDidFinishLoading) name: MPMoviePlayerContentPreloadDidFinishNotification object: moviePlayer];
					[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(moviePlayBackDidFinish) name: MPMoviePlayerPlaybackDidFinishNotification object: moviePlayer];
				}
							
				else
				{
					NSLog(@"Rejected File Type:*%@*",fileType);
					
					UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
																		message:NSLocalizedString(@"This file type does not support previewing in Handshake.", @"warning on unknown filetype preview") 
																	   delegate:nil 
															  cancelButtonTitle:nil 
															  otherButtonTitles:NSLocalizedString(@"Okay", @"Out of memory warning action"),nil];
					[alertView show];
					[alertView release];	
				}
			}
		}
	}
	
	[tableView reloadData];
}

-(void) moviePlayBackDidFinish
{
	[moviePlayer release];
}

-(void) selectMass
{
	[self populateSelectedArray];
	inMassSelectMode = !inMassSelectMode;

	diskSpaceLabel.hidden = inMassSelectMode;
	freeSpaceTabBar.hidden = inMassSelectMode;
	
	sendButton.enabled = !inMassSelectMode;
	deleteButton.enabled = !inMassSelectMode;
	
	[sendButton setTitle: NSLocalizedString(@"Send", @"Send Button") forState:UIControlStateNormal];
	[deleteButton setTitle:  NSLocalizedString(@"Send", @"Delete Button") forState:UIControlStateNormal];
	
	[sendButton setEnabled: NO];
	[deleteButton setEnabled: NO];
	
	if(inMassSelectMode)
	{
		self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Cancel", @"Cancel Button");
		self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStyleDone;
		self.navigationItem.hidesBackButton = TRUE;
	}

	else
	{
		self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Select", @"Select Button");
		self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStylePlain;
		self.navigationItem.hidesBackButton = FALSE;
	}
		
	[fileBrowserTableView reloadData];
	
}

- (IBAction)massSend:(id)sender
{
	for(int x = 0; x < [self.selectedArray count]; x++)
	{		
		if([[self.selectedArray objectAtIndex: x] boolValue] == TRUE)
		{
			NSLog(@"User wishes to send: %@", [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@",  [self.fileArray objectAtIndex:x]]]);
		}
	}
	
}

- (IBAction)massDelete:(id)sender
{	
	NSMutableArray *indexArray = [[NSMutableArray alloc] init];	
	for(int x = 0; x < [self.selectedArray count]; x++)
	{		
		if([[self.selectedArray objectAtIndex: x] boolValue] == TRUE)
		{
			[[NSFileManager defaultManager] removeItemAtPath:[self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@",  [self.fileArray objectAtIndex:x]]] error:nil];
			[indexArray addObject:[NSIndexPath indexPathForRow:x inSection:0]];
					
		}
	}
	
	[self.fileArray removeAllObjects];
	self.fileArray = [NSMutableArray arrayWithArray: [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workingDirectory error:NULL]];
	
	[self populateSelectedArray];


	[fileBrowserTableView beginUpdates];
	[fileBrowserTableView deleteRowsAtIndexPaths: indexArray  withRowAnimation: UITableViewRowAnimationFade];
	[fileBrowserTableView endUpdates];
	
	[indexArray release];
	[fileBrowserTableView reloadData];
	
	[sendButton setTitle: NSLocalizedString(@"Send", @"Send Button") forState:UIControlStateNormal];
	[deleteButton setTitle:  NSLocalizedString(@"Send", @"Delete Button") forState:UIControlStateNormal];

	[sendButton setEnabled: NO];
	[deleteButton setEnabled: NO];
}

- (void)populateSelectedArray
{
	numObjectsSelected = 0;
	
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:[fileArray count]];
	for (int i=0; i < [fileArray count]; i++)
		[array addObject:[NSNumber numberWithBool:NO]];
	self.selectedArray = array;
	
	[array release]; 
} 

-(void) movieDidFinishLoading
{
	[moviePlayer play];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	self.rootDocumentPath = nil;
	self.workingDirectory = nil;
	self.fileArray = nil;
	self.selectedArray = nil;
	self.selectedImage = nil;
	self.unselectedImage = nil;
	
	[super dealloc];
}


@end
