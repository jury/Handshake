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

/*
// Override initWithNibName:bundle: to load the view using a nib file then perform additional customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically.
- (void)loadView {
}
*/


-(id)initWithDirectory:(NSString *)directory
{
	self = [super initWithNibName:@"FileBrowserViewController" bundle:nil];
	self.workingDirectory = directory;
	
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
	
	/*
	[[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"Apple" ofType:@"html"] toPath:[NSString stringWithFormat: @"%@/htm1.html", self.workingDirectory] error:nil];	
	[[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"cnn" ofType:@"html"] toPath:[NSString stringWithFormat: @"%@/htm2.html", self.workingDirectory] error:nil];	
	[[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"digg" ofType:@"html"] toPath:[NSString stringWithFormat: @"%@/htm3.html", self.workingDirectory] error:nil];	
	 */
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
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
		
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
		[cell setSelectionStyle: UITableViewCellSelectionStyleNone];

		UILabel *label = [[UILabel alloc] initWithFrame:kLabelRect];
		label.tag = kCellLabelTag;
		label.backgroundColor = [UIColor clearColor];
		[cell.contentView addSubview:label];
		[label release];
		
		UILabel *dateLabel = [[UILabel alloc] initWithFrame:kDateRect];
		dateLabel.tag = kCellDateTag;
		[dateLabel setFont: [UIFont systemFontOfSize: 12]];
		[dateLabel setTextColor: [UIColor grayColor]];
		dateLabel.backgroundColor = [UIColor clearColor];
		[cell.contentView addSubview:dateLabel];
		[dateLabel release];
		
		UILabel *sizeLabel = [[UILabel alloc] initWithFrame:kSizeLabel];
		sizeLabel.tag = kCellSizeTag;
		[sizeLabel setFont: [UIFont systemFontOfSize: 10]];
		[sizeLabel setTextAlignment: UITextAlignmentRight];
		sizeLabel.backgroundColor = [UIColor clearColor];
		[sizeLabel setTextColor: [UIColor grayColor]];
		[cell.contentView addSubview:sizeLabel];
		[sizeLabel release];
		
		
		UIImageView *imageView = [[UIImageView alloc] initWithImage:unselectedImage];
		imageView.frame = CGRectMake(5.0, 22.0, 23.0, 23.0);
		[cell.contentView addSubview:imageView];
		imageView.hidden = !inMassSelectMode;
		imageView.tag = kCellImageViewTag;
		[imageView release];
		
		if([[NSFileManager defaultManager] fileExistsAtPath:[self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] isDirectory:&isDirectory])
		{
			if(isDirectory)
			{
				
				UIImageView *imageView = [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"folder.png"]];
				
				imageView.frame = CGRectMake(5.0, 10.0, 23.0, 23.0);
				
				[cell.contentView addSubview:imageView];
				imageView.tag = kCellIconTag;
				[imageView release];
			}
			
			else
			{
				UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed: @"files.png"]];
				
				imageView.frame = CGRectMake(5.0, 10.0, 23.0, 23.0);
				
				[cell.contentView addSubview:imageView];
				imageView.tag = kCellIconTag;
				[imageView release];
			}
		}
			
		
	}
	
	
	[[NSFileManager defaultManager] fileExistsAtPath:[self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] isDirectory:&isDirectory];
	
	[UIView beginAnimations:@"cell shift" context:nil];
	
	UILabel *label = (UILabel *)[cell.contentView viewWithTag:kCellLabelTag];
	label.text = [self.fileArray objectAtIndex: [indexPath row]];
	label.frame = (inMassSelectMode) ? kLabelIndentedRect : kLabelRect;
	label.opaque = NO;
	
	UILabel *dateLabel = (UILabel *)[cell.contentView viewWithTag:kCellDateTag];
	NSDate *fileDate = [[[NSFileManager defaultManager] fileAttributesAtPath: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] traverseLink:NO] objectForKey: @"NSFileModificationDate"];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"MMM dd, yyyy HH:MM"];
	dateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate: fileDate]];
	dateLabel.frame = (inMassSelectMode) ? kDateIndentedRect : kDateRect;
	dateLabel.opaque = NO;
	
	[dateFormatter release];

	
	if(!isDirectory)
	{
		UILabel *sizeLabel = (UILabel *)[cell.contentView viewWithTag:kCellSizeTag];
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
		UILabel *sizeLabel = (UILabel *)[cell.contentView viewWithTag:kCellSizeTag];
		sizeLabel.text = [NSString stringWithFormat: @"%i Items", [[[NSFileManager defaultManager] contentsOfDirectoryAtPath: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] error: nil] count]];
		sizeLabel.opaque = NO;	
	}
	
	UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:kCellImageViewTag];
	NSNumber *selected = [selectedArray objectAtIndex:[indexPath row]];
	imageView.image = ([selected boolValue]) ? selectedImage : unselectedImage;
	imageView.hidden = !inMassSelectMode;
	
	UIImageView *iconView = (UIImageView *)[cell.contentView viewWithTag:kCellIconTag];
	iconView.frame = (inMassSelectMode) ? kIconIndet : kIconRect;
	iconView.image = (isDirectory) ? [UIImage imageNamed: @"folder.png"] : [UIImage imageNamed: @"files.png"];

	[UIView commitAnimations];
	
	if(inMassSelectMode)
	{
		if(imageView.image == selectedImage)
		{
			UIImageView *backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed: @"cellBackground.png"]];
			cell.backgroundView = backgroundImage;
			[backgroundImage release];
		}
		else
		{
			cell.backgroundView = nil;
		}
	}
	
	else
	{
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
	
	
}

- (void)populateSelectedArray
{
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
