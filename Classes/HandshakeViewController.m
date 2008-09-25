//
//  HandshakeViewController.m
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//

#define DEBUG

#import "HandshakeViewController.h"
#import "AddressBook/AddressBook.h"

@implementation HandshakeViewController



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



// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
		
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	#ifdef DEBUG
//	NSLog(@"%@", [defaults dictionaryRepresentation]);
	#endif
	
	
	
	
	ABAddressBookRef addressBook = ABAddressBookCreate();
	
	NSArray *addresses = (NSArray *) ABAddressBookCopyArrayOfAllPeople(addressBook);
	NSInteger addressesCount = [addresses count];
	
	for (int i = 0; i < addressesCount; i++) {
		ABRecordRef record = [addresses objectAtIndex:i];
		NSString *firstName = (NSString *)ABRecordCopyValue(record, kABPersonFirstNameProperty);
		NSString *lastName = (NSString *)ABRecordCopyValue(record, kABPersonLastNameProperty);
	
		CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook); 
		
		//NSLog(@"%@", mobile);
		
		//NSLog(@"%@", people);
	//	NSLog(@"%@",ABMultiValueCopyValueAtIndex(ABRecordCopyValue(CFArrayGetValueAtIndex(people, i),kABPersonPhoneProperty) ,0));
		NSLog(@"%@ %@", firstName, lastName);
		NSLog(@"%@", people);
		NSLog(@"%@",ABMultiValueCopyValueAtIndex(ABRecordCopyValue(CFArrayGetValueAtIndex(people, i),kABPersonPhoneProperty) ,0));

		
	//	NSString *type = (NSString *)ABRecordCopyValue(record, kABPersonEmailProperty);
	//	NSInteger *group = (NSInteger *)ABRecordCopyValue(record, kABPersonPhoneMobileLabel);
		//UIImageView *contactImage = (UIImageView *)ABPersonCopyImageData(record);		
	//	NSLog(@"%@ %@ of email: %@ and Group", firstName, lastName, type);
	

		
		[firstName release];
		[lastName release];
	}
	
	
	
    [super viewDidLoad];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}

@end
