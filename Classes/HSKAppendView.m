//
//  HSKAppendView.m
//  Handshake
//
//  Created by Kyle on 10/27/08.
//  Copyright 2008 Dragon Forged Software. All rights reserved.
//

#import "HSKAppendView.h"


@implementation HSKAppendView

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[appendTextField resignFirstResponder];
	
	return YES;
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

- (void)viewWillAppear:(BOOL)animated 
{
    
	if([[NSUserDefaults standardUserDefaults] objectForKey: @"appendString"] != nil)
		appendTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey: @"appendString"];
		
		
	[super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
 {

    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated 
{
	//save on the way out
	[[NSUserDefaults standardUserDefaults] setObject: appendTextField.text forKey:@"appendString"];
	 
}

/*
- (void)viewDidDisappear:(BOOL)animated {
}
*/
/*
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
*/

- (void)dealloc {
    [super dealloc];
}


@end

