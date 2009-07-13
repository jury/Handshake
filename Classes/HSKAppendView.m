//
//  HSKAppendView.m
//  Handshake
//
//  Created by Kyle on 10/27/08.
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

#import "HSKAppendView.h"


@implementation HSKAppendView

+(void) initialize
{
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString (@"Sent by $name on $date", @"Appended text do not localize $name or $date"), @"appendString", nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults: dictionary];
}


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
    
	[appendTextField becomeFirstResponder];
	
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

