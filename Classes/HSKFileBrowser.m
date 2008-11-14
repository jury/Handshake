//
//  HSKFileBrowser.m
//  Handshake
//
//  Created by Kyle on 11/6/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKFileBrowser.h"
#import "HSKFileViewerViewController.h"
#import "HSKFilePicturePreviewController.h"
#import "HSKFileTextViewController.h"
#import "HSKFileAdditonalDetailsView.h"

@implementation HSKFileBrowser

@synthesize rootDocumentPath, workingDirectory, fileArray, selectedArray, selectedImage, unselectedImage;

-(id)initWithDirectory:(NSString *)directory
{
	self = [super initWithNibName:@"FileBrowserViewController" bundle:nil];
	self.workingDirectory = directory;
	
	for(int x = 0; x < 12; x++)
		[[NSFileManager defaultManager] createDirectoryAtPath: [NSString stringWithFormat:@"%@/folder%i", self.workingDirectory, x] attributes:nil];
	
	return self;
}

// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
	bottomTabBar.hidden = TRUE;
	inMassSelectMode = FALSE;
	
    [super viewDidLoad];
	
	self.fileArray = [NSMutableArray arrayWithArray: [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workingDirectory error:NULL]];
	self.navigationItem.title = [self.workingDirectory lastPathComponent];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStylePlain target:self action:@selector(selectMass)] autorelease];
	
	//clear out the selected database
	[self populateSelectedArray];
	self.selectedImage = [UIImage imageNamed:@"selected.png"];
	self.unselectedImage = [UIImage imageNamed:@"unselected.png"];
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
	
	UIImage *folderImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"folder" ofType:@"png"]];
	UIImage *fileImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"files" ofType:@"png"]];
	
	BOOL isDirectory = FALSE;
	[[NSFileManager defaultManager] fileExistsAtPath:[self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] isDirectory:&isDirectory];

	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) 
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
		
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		[cell setSelectionStyle: UITableViewCellSelectionStyleNone];

		UILabel *label = [[UILabel alloc] initWithFrame:kLabelRect];
		label.tag = kCellLabelTag;
		[cell.contentView addSubview:label];
		[label release];
		
		UILabel *dateLabel = [[UILabel alloc] initWithFrame:kDateRect];
		dateLabel.tag = kCellDateTag;
		[dateLabel setFont: [UIFont systemFontOfSize: 12]];
		[dateLabel setTextColor: [UIColor grayColor]];
		[cell.contentView addSubview:dateLabel];
		[dateLabel release];
		
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
	iconView.image = (isDirectory) ? folderImage : fileImage;
	
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
			double convertedSize = [fileSize doubleValue] / 1024/1024;
			sizeLabel.text = [NSString stringWithFormat: @"%0.1f MBs", convertedSize] ;
		}
		
		sizeLabel.opaque = NO;
	}
	
	else
	{
		sizeLabel = (UILabel *)[cell.contentView viewWithTag:kCellSizeTag];
		sizeLabel.text = [NSString stringWithFormat: @"%i Items", [[[NSFileManager defaultManager] contentsOfDirectoryAtPath: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] error: nil] count]];
		sizeLabel.opaque = NO;	
	}
	
	UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:kCellImageViewTag];
	NSNumber *selected = [selectedArray objectAtIndex:[indexPath row]];
	imageView.image = ([selected boolValue]) ? selectedImage : unselectedImage;
	imageView.hidden = !inMassSelectMode;
	

	
	[UIView commitAnimations];
	
	if(inMassSelectMode)
	{
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
		cell.backgroundView = nil;
	}
		
	
	[folderImage release];
	[fileImage release];
	
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
		
		[sendButton setTitle: [NSString stringWithFormat:@"Send (%i)", numObjectsSelected]];
		[deleteButton setTitle: [NSString stringWithFormat:@"Delete (%i)", numObjectsSelected]];
		
		
		if(numObjectsSelected > 0)
		{
			[sendButton setEnabled: YES];
			[deleteButton setEnabled: YES];
		}
		
		else
		{
			[sendButton setEnabled: NO];
			[deleteButton setEnabled: NO];	
			
			[sendButton setTitle: @"Send"];
			[deleteButton setTitle: @"Delete"];
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
				if([fileType isEqualToString:@"html"] || [fileType isEqualToString:@"htm"] || [fileType isEqualToString:@"pdf"] || [fileType isEqualToString:@"xls"] || [fileType isEqualToString:@"doc"] || [fileType isEqualToString:@"zip"] || [fileType isEqualToString:@"txt"])
				{
					HSKFileViewerViewController *fileBrowserViewController = [[HSKFileViewerViewController alloc] initWithFile: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]]];		
					[self.navigationController pushViewController:fileBrowserViewController animated: YES];
					[fileBrowserViewController release];
					
				}
				
				//handle with UIImage
				else if ([fileType isEqualToString:@"png"] || [fileType isEqualToString:@"jpg"] || [fileType isEqualToString:@"pict"] || [fileType isEqualToString:@"gif"] || [fileType isEqualToString:@"jpeg"] || [fileType isEqualToString:@"tiff"])
				{
				
					HSKFilePicturePreviewController *picPreviewController = [[HSKFilePicturePreviewController alloc] initWithFile:[self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]]];
					[self.navigationController pushViewController:picPreviewController animated: YES];
					[picPreviewController release];
				}
				
				//handle with movie player
				else if ([fileType isEqualToString:@"mov"] ||[fileType isEqualToString:@"mp3"] ||[fileType isEqualToString:@"mpg"] || [fileType isEqualToString:@"mpeg"] || [fileType isEqualToString:@"caf"] || [fileType isEqualToString:@"aiff"] || [fileType isEqualToString:@"wav"] ||[fileType isEqualToString:@"m4v"]||[fileType isEqualToString:@"aac"]||[fileType isEqualToString:@"mp4"])
				{
					moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:  [NSURL fileURLWithPath: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]]]];
					moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
					moviePlayer.movieControlMode = MPMovieControlModeDefault;
					moviePlayer.backgroundColor = [UIColor blackColor];
					
				
					[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(movieDidFinishLoading) name: MPMoviePlayerContentPreloadDidFinishNotification object: moviePlayer];
					[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(moviePlayBackDidFinish) name: MPMoviePlayerPlaybackDidFinishNotification object: moviePlayer];
				}
				
				//handle with UIText
				else if ([fileType isEqualToString:@"log"])
				{
					HSKFileTextViewController *textViewController = [[HSKFileTextViewController alloc] initWithFile:[self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]]];
					[self.navigationController pushViewController:textViewController animated: YES];
					[textViewController release];
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
	NSLog(@"Releasing Movie Player");
	[moviePlayer release];

}

-(void) selectMass
{
	[self populateSelectedArray];
	inMassSelectMode = !inMassSelectMode;	
	bottomTabBar.hidden = !inMassSelectMode;
	
	
	[sendButton setTitle: @"Send"];
	[deleteButton setTitle: @"Delete"];
	
	[sendButton setEnabled: NO];
	[deleteButton setEnabled: NO];
	
	if(inMassSelectMode)
	{
		self.navigationItem.rightBarButtonItem.title = @"Cancel";
		self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStyleDone;
		self.navigationItem.hidesBackButton = TRUE;
	}
	else
	{
		self.navigationItem.rightBarButtonItem.title = @"Select";
		self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStylePlain;
		self.navigationItem.hidesBackButton = FALSE;
	}
		
	[fileBrowserTableView reloadData];
	
}

- (IBAction)massSend:(id)sender
{
	
	
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
	
	[fileBrowserTableView deleteRowsAtIndexPaths: indexArray  withRowAnimation: UITableViewRowAnimationFade];
	[indexArray release];
	
	[self.fileArray removeAllObjects];
	self.fileArray = [NSMutableArray arrayWithArray: [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workingDirectory error:NULL]];
	[self populateSelectedArray];
	[fileBrowserTableView reloadData];
	
	[sendButton setTitle: @"Send"];
	[deleteButton setTitle: @"Delete"];
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
	

	
    [super dealloc];
}


@end
