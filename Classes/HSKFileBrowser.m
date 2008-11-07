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

@implementation HSKFileBrowser

@synthesize rootDocumentPath, workingDirectory, fileArray;

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
    [super viewDidLoad];
	
	self.fileArray = [NSMutableArray arrayWithArray: [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workingDirectory error:NULL]];
	self.navigationItem.title = [self.workingDirectory lastPathComponent];

	/*
	NSError *error;
	
	[[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"sent" ofType:@"caf"] toPath: [NSString stringWithFormat: @"%@/sent.caf", self.workingDirectory] error:&error];
	[[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"receive" ofType:@"caf"] toPath:[NSString stringWithFormat: @"%@/receive.caf", self.workingDirectory] error:nil];
	[[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"Scorecard" ofType:@"png"] toPath:[NSString stringWithFormat: @"%@/Scorecard.png", self.workingDirectory] error:nil];
	[[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"Tower" ofType:@"png"] toPath:[NSString stringWithFormat: @"%@/Tower.png", self.workingDirectory] error:nil];
	[[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"dfsw" ofType:@"png"] toPath:[NSString stringWithFormat: @"%@/dfsw.png", self.workingDirectory] error:nil];
	[[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"Apple" ofType:@"html"] toPath:[NSString stringWithFormat: @"%@/htmldoc.html", self.workingDirectory] error:nil];

	 [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"large" ofType:@"pdf"] toPath:[NSString stringWithFormat: @"%@/large.pdf", self.workingDirectory] error:nil];
	 [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"movie" ofType:@"mov"] toPath:[NSString stringWithFormat: @"%@/movie.mov", self.workingDirectory] error:nil];
	 [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"song" ofType:@"mp3"] toPath:[NSString stringWithFormat: @"%@/song.mp3", self.workingDirectory] error:nil];
	 [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"pages" ofType:@"pages"] toPath:[NSString stringWithFormat: @"%@/pages.pages", self.workingDirectory] error:nil];
	 [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"Growl" ofType:@"log"] toPath:[NSString stringWithFormat: @"%@/Growl.log", self.workingDirectory] error:nil];
	 [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"huge" ofType:@"pdf"] toPath:[NSString stringWithFormat: @"%@/huge.pdf", self.workingDirectory] error:nil];
	 [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"richtext" ofType:@"rtf"] toPath:[NSString stringWithFormat: @"%@/richtext.rtf", self.workingDirectory] error:nil];	
	 [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"Movie" ofType:@"m4v"] toPath:[NSString stringWithFormat: @"%@/Movie.m4v", self.workingDirectory] error:nil];	

	 
	 NSLog(@"%@", [error localizedDescription]);
	 
	*/

	[[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"excel" ofType:@"txt"] toPath:[NSString stringWithFormat: @"%@/excel.xls.zip", self.workingDirectory] error:nil];	

	[[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"doc" ofType:@"txt"] toPath:[NSString stringWithFormat: @"%@/doc.zip", self.workingDirectory] error:nil];	


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
	}
	
	cell.text = [self.fileArray objectAtIndex: [indexPath row]];
	
	
	if([[NSFileManager defaultManager] fileExistsAtPath:[self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]] isDirectory:&isDirectory])
	{
		if(isDirectory)
		{
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			[cell setImage: [UIImage imageNamed: @"folder.png"]];
		}
		
		else
		{
			[cell setImage: [UIImage imageNamed: @"files.png"]];
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
	
	

	// Configure the cell
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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

			//handle in webview
			if([fileType isEqualToString:@"html"] || [fileType isEqualToString:@"htm"] || [fileType isEqualToString:@"pdf"] || [fileType isEqualToString:@"xls"] || [fileType isEqualToString:@"doc"] || [fileType isEqualToString:@"zip"])
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
			else if ([fileType isEqualToString:@"mov"] ||[fileType isEqualToString:@"mp3"] ||[fileType isEqualToString:@"mpg"] || [fileType isEqualToString:@"mpeg"] || [fileType isEqualToString:@"caf"] || [fileType isEqualToString:@"aiff"] || [fileType isEqualToString:@"wav"] ||[fileType isEqualToString:@"m4v"])
			{
				moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:  [NSURL fileURLWithPath: [self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]]]];
				moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
				moviePlayer.movieControlMode = MPMovieControlModeDefault;
				moviePlayer.backgroundColor = [UIColor blackColor];
				
			
				[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(movieDidFinishLoading) name: MPMoviePlayerContentPreloadDidFinishNotification object: moviePlayer];
				[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(moviePlayBackDidFinish) name: MPMoviePlayerPlaybackDidFinishNotification object: moviePlayer];
			}
			
			//handle with UIText
			else if ([fileType isEqualToString:@"log"] || [fileType isEqualToString:@"txt"] || [fileType isEqualToString:@"rtf"])
			{
				HSKFileTextViewController *textViewController = [[HSKFileTextViewController alloc] initWithFile:[self.workingDirectory stringByAppendingString: [NSString stringWithFormat: @"/%@", [fileArray objectAtIndex: [indexPath row]]]]];
				[self.navigationController pushViewController:textViewController animated: YES];
				[textViewController release];
			}
			
			
			else
			{
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

	
	[tableView reloadData];
}

-(void) moviePlayBackDidFinish
{
	NSLog(@"Releasing Movie Player");
	[moviePlayer release];
	
	
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
