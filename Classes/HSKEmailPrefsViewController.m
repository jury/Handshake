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

@interface HSKEmailPrefsViewController ()

- (void)validateFields;

@end

@implementation HSKEmailPrefsViewController

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Email Settings", @"Email Settings preferences view title");
    self.tableView.sectionFooterHeight = 0.0;
    self.tableView.sectionHeaderHeight = 10.0;
}

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
            cell.entryField.placeholder = @"jon@me.com";
            cell.entryField.keyboardType = UIKeyboardTypeEmailAddress;
            cell.entryField.tag = 1;
            cell.entryField.delegate = self;
            break;
        case 1:
            cell.labelLabel.text = @"Host Name";
            cell.entryField.secureTextEntry = NO;
            cell.entryField.placeholder = @"smtp.me.com";
            cell.entryField.keyboardType = UIKeyboardTypeURL;
            cell.entryField.tag = 2;
            cell.entryField.delegate = self;
            break;
        case 2:
            cell.labelLabel.text = @"User Name";
            cell.entryField.secureTextEntry = NO;
            cell.entryField.placeholder = @"Optional";
            cell.entryField.keyboardType = UIKeyboardTypeEmailAddress;
            cell.entryField.tag = 3;
            cell.entryField.delegate = self;
            break;
        case 3:
            cell.labelLabel.text = @"Password";
            cell.entryField.secureTextEntry = YES;
            cell.entryField.placeholder = @"Optional";
            cell.entryField.keyboardType = UIKeyboardTypeDefault;
            cell.entryField.tag = 0;
            cell.entryField.delegate = self;
            break;
    }
    
    return cell;
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
    
    [self validateFields];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self performSelector:@selector(resizeTable) withObject:nil afterDelay:0.5];
}


- (void)resizeTable
{
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

#pragma mark -
#pragma mark UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"text field finished editing");
    
    if (textField.tag != 1)
        return;
    
    HSKEmailDomain domainType = kHSKEmailDomainCustom;
    
    NSArray *components = [textField.text componentsSeparatedByString:@"@"];
    NSString *emailAddress = textField.text;
    NSString *userName = [components objectAtIndex:0];
    
    if ([components count] == 2)
    {
        NSString *domain = [[components lastObject] lowercaseString];
        if ([domain isEqualToString:@"gmail.com"])
        {
            domainType = kHSKEmailDomainGmail;
        }
        else if ([domain isEqualToString:@"apple.com"])
        {
            domainType = kHSKEmailDomainApple;
        }
        else if ([domain isEqualToString:@"mac.com"] || [domain isEqualToString:@"me.com"])
        {
            domainType = kHSKEmailDomainDotMac;
        }
        else if ([domain isEqualToString:@"aol.com"])
        {
            domainType = kHSKEmailDomainAOL;
        }
        else if ([domain isEqualToString:@"yahoo.com"])
        {
            domainType = kHSKEmailDomainYahoo;
        }
    }
    
    if (domainType == kHSKEmailDomainCustom)
        return;
    
    HSKPrefsEntryCell *prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    if ([prefsEntryCell.entryField.text length] == 0)
    {
        switch(domainType)
        {
            case kHSKEmailDomainAOL:
                prefsEntryCell.entryField.text = @"smtp.aol.com";
                break;
            case kHSKEmailDomainApple:
                prefsEntryCell.entryField.text = @"relay.apple.com";
                break;
            case kHSKEmailDomainDotMac:
                prefsEntryCell.entryField.text = @"smtp.me.com";
                break;
            case kHSKEmailDomainGmail:
                prefsEntryCell.entryField.text = @"smtp.gmail.com";
                break;
            case kHSKEmailDomainYahoo:
                prefsEntryCell.entryField.text = @"plus.smtp.mail.yahoo.com";
                break;
        }
    }
    
    prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    if ([prefsEntryCell.entryField.text length] == 0)
    {
        switch(domainType)
        {
            case kHSKEmailDomainAOL:
                prefsEntryCell.entryField.text = userName;
                break;
            case kHSKEmailDomainApple:
                /* nothing, auth not used */
                break;
            case kHSKEmailDomainDotMac:
                prefsEntryCell.entryField.text = emailAddress;
                break;
            case kHSKEmailDomainGmail:
                prefsEntryCell.entryField.text = emailAddress;
                break;
            case kHSKEmailDomainYahoo:
                prefsEntryCell.entryField.text = userName;
                break;
        }
    }
    
    [self validateFields];
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // This is a bit of a hack, but it's what I've got
        
    HSKPrefsEntryCell *prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:textField.tag inSection:0]];
    [prefsEntryCell.entryField becomeFirstResponder];
    
    return YES;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self performSelector:@selector(validateFields) withObject:nil afterDelay:0.0];
    
    return YES;
}

- (void)validateFields
{
    BOOL fieldsValid = YES;
    
    HSKPrefsEntryCell *prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if ([prefsEntryCell.entryField.text length] == 0)
    {
        fieldsValid = NO;
    }
    
    NSUInteger atLocation = [prefsEntryCell.entryField.text rangeOfString:@"@"].location;
    NSUInteger dotLocation = [prefsEntryCell.entryField.text rangeOfString:@"."].location;
    
    // Contains "@", "." and "@" precedes "."
    if ((atLocation == NSNotFound) || (dotLocation == NSNotFound) || (atLocation > dotLocation))
    {
        fieldsValid = NO;
    }
    
    prefsEntryCell = (HSKPrefsEntryCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    if ([prefsEntryCell.entryField.text length] == 0)
    {
        fieldsValid = NO;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = fieldsValid;
}

@end

