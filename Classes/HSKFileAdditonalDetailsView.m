//
//  HSKFileAdditonalDetailsView.m
//  Handshake
//
//  Created by Kyle on 11/11/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKFileAdditonalDetailsView.h"


@implementation HSKFileAdditonalDetailsView

@synthesize workingDirectory;

-(id) initWithFile: (NSString *)filePath
{
	
	self = [super initWithNibName: @"fileDetailView" bundle:nil];
	
	self.workingDirectory = filePath;
	
	self.navigationItem.title = [self.workingDirectory lastPathComponent];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStylePlain target:self action:@selector(sendObject)] autorelease];

	return self;
}


-(void) sendObject
{
	
}

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   
	if(section == 0)
		return 1;
	if(section == 1)
		return 4;
	
	return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		[cell setSelectionStyle: UITableViewCellSelectionStyleNone];

    }
	
	
	//file name
	if([indexPath section] == 0 && [indexPath row] == 0)
		cell.text = [self.workingDirectory lastPathComponent];
	
	if([indexPath section] == 1)
	{
		if([indexPath row] == 0)
		{
			NSNumber *fileSize = [[[NSFileManager defaultManager] fileAttributesAtPath: self.workingDirectory traverseLink:NO] objectForKey: @"NSFileSize"];
			
			BOOL isDirectory = FALSE;

			[[NSFileManager defaultManager] fileExistsAtPath:self.workingDirectory isDirectory:&isDirectory];
			
			if(!isDirectory)
			{
				if([fileSize doubleValue] < 1023)
					cell.text =[NSString stringWithFormat: @"File Size: %f Bytes", fileSize] ;
				else if([fileSize doubleValue] < 1048576)
				{
					double convertedSize = [fileSize doubleValue] / 1024;
					cell.text =[NSString stringWithFormat: @"File Size: %0.2f KBs", convertedSize] ;
				}
				else
				{
					double convertedSize = [fileSize doubleValue] / 1024/1024;
					cell.text =[NSString stringWithFormat: @"File Size: %0.2f MBs", convertedSize] ;
				}
			}
			
			else
			{
				cell.text =[NSString stringWithFormat: @"Folder contains %i Items", [[[NSFileManager defaultManager] contentsOfDirectoryAtPath: self.workingDirectory error: nil] count]];
				
			}
		}
		if([indexPath row] == 1)
		{
			NSDate *fileDate = [[[NSFileManager defaultManager] fileAttributesAtPath: self.workingDirectory traverseLink:NO] objectForKey: @"NSFileCreationDate"];
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"MMM dd, yyyy HH:MM"];
			cell.text = [NSString stringWithFormat:@"Creation: %@", [dateFormatter stringFromDate: fileDate]];
	
			[dateFormatter release];
		}
		if([indexPath row] == 2)
		{
			NSDate *fileDate = [[[NSFileManager defaultManager] fileAttributesAtPath: self.workingDirectory traverseLink:NO] objectForKey: @"NSFileModificationDate"];
			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"MMM dd, yyyy HH:MM"];
			cell.text = [NSString stringWithFormat:@"Modifcation: %@", [dateFormatter stringFromDate: fileDate]];
			
			[dateFormatter release];
		}
		if([indexPath row] == 3)
		{
			
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			NSString *documentsDirectory = [paths objectAtIndex:0];
			cell.text = [NSString stringWithFormat: @"Path: %@", [self.workingDirectory stringByReplacingOccurrencesOfString: documentsDirectory withString:@"" ]];
		}
	
		
		
	}
	
    // Configure the cell
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	
	if(section == 0)
		return @"File Name";
	else
		return @"More Info";
	
	return nil;
	
}

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}
*/

/*
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
    }
    if (editingStyle == UITableViewCellEditingStyleInsert) {
    }
}
*/

/*
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
}
*/
/*
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
*/

- (void)dealloc 
{
	self.workingDirectory = nil;
    [super dealloc];
}


@end

