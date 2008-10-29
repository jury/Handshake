//
//  HSKPrefsTableViewController.m
//  Handshake
//
//  Created by Ian Baird on 10/28/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "HSKEmailPrefsViewController.h"
#import "HSKPrefsEntryCell.h"

NSString *HSKMailAddressDefault = @"HSKMailAddressDefault";
NSString *HSKMailHostPortDefault = @"HSKMailHostPortDefault";
NSString *HSKMailLoginDefault = @"HSKMailLoginDefault";
NSString *HSKMailPasswordDefault = @"HSKMailPasswordDefault";

@implementation HSKEmailPrefsViewController

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
- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    
}
*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"HSKPrefsEntryCell";
    
    HSKPrefsEntryCell *cell = (HSKPrefsEntryCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {
        NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"HSKPrefsEntryCell" owner:self options:nil];
        cell = [objects lastObject];
    }
    
    switch (indexPath.row)
    {
        case 0:
            cell.labelLabel.text = @"Address";
            cell.entryField.secureTextEntry = NO;
            cell.entryField.placeholder = @"jonappleseed@me.com";
            cell.entryField.keyboardType = UIKeyboardTypeEmailAddress;
            break;
        case 1:
            cell.labelLabel.text = @"Host Name";
            cell.entryField.secureTextEntry = NO;
            cell.entryField.placeholder = @"smtp.me.com";
            cell.entryField.keyboardType = UIKeyboardTypeURL;
            break;
        case 2:
            cell.labelLabel.text = @"User Name";
            cell.entryField.secureTextEntry = NO;
            cell.entryField.placeholder = @"Optional";
            cell.entryField.keyboardType = UIKeyboardTypeDefault;
            break;
        case 3:
            cell.labelLabel.text = @"Password";
            cell.entryField.secureTextEntry = YES;
            cell.entryField.placeholder = @"Optional";
            cell.entryField.keyboardType = UIKeyboardTypeDefault;
            break;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Email Settings";
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



- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
        
    [self.tableView reloadData];
        
    HSKPrefsEntryCell *prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    prefsEntryCell.entryField.text = [[NSUserDefaults standardUserDefaults] stringForKey:HSKMailAddressDefault];
    [prefsEntryCell.entryField becomeFirstResponder];
    
    prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    prefsEntryCell.entryField.text = [[NSUserDefaults standardUserDefaults] stringForKey:HSKMailHostPortDefault];
    
    prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    prefsEntryCell.entryField.text = [[NSUserDefaults standardUserDefaults] stringForKey:HSKMailLoginDefault];
    
    // TODO: replace with keychain
    prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    prefsEntryCell.entryField.text = [[NSUserDefaults standardUserDefaults] stringForKey:HSKMailPasswordDefault];
    
    CGRect newFrame = self.tableView.frame;
    newFrame.size.height = 200.0;
    
    self.tableView.frame = newFrame;
}


- (void)viewWillDisappear:(BOOL)animated 
{
    HSKPrefsEntryCell *prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [prefsEntryCell.entryField resignFirstResponder];
    [[NSUserDefaults standardUserDefaults] setObject:prefsEntryCell.entryField.text forKey:HSKMailAddressDefault];
    
    prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [prefsEntryCell.entryField resignFirstResponder];
    [[NSUserDefaults standardUserDefaults] setObject:prefsEntryCell.entryField.text forKey:HSKMailHostPortDefault];
    
    prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [prefsEntryCell.entryField resignFirstResponder];
    [[NSUserDefaults standardUserDefaults] setObject:prefsEntryCell.entryField.text forKey:HSKMailLoginDefault];
    
    prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    [prefsEntryCell.entryField resignFirstResponder];
    [[NSUserDefaults standardUserDefaults] setObject:prefsEntryCell.entryField.text forKey:HSKMailPasswordDefault];
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

