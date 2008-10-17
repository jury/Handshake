//
//  HSKViewController.m
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//

#import "HSKMainViewController.h"
#import "NSString+SKPPhoneAdditions.h"
#import "UIImage+ThumbnailExtensions.h"
#import "HSKUnknownPersonViewController.h"
#import "HSKFlipsideController.h"
#import "HSKPicturePreviewViewController.h"
#import "HSKNavigationController.h"
#import "HSKCustomAdController.h"
#import "Beacon.h"


#ifdef HS_PREMIUM
#define kHSKTableHeaderHeight 73.0;
#else
#define kHSKTableHeaderHeight 119.0;
#endif

#pragma mark -
#pragma mark ABHelper methods

static inline CFTypeRef ABRecordCopyValueAndAutorelease(ABRecordRef record, ABPropertyID property)
{
    return [(id) ABRecordCopyValue(record, property) autorelease];
}

static inline CFTypeRef ABMultiValueCopyValueAtIndexAndAutorelease(ABMultiValueRef multiValue, CFIndex index)
{
    return [(id) ABMultiValueCopyValueAtIndex(multiValue, index) autorelease];
}

#pragma mark -
#pragma mark Class Extension

@interface HSKMainViewController ()

@property(nonatomic, retain) id lastMessage;
@property(nonatomic, retain) id lastPeer;
@property(nonatomic, retain) UIButton *frontButton;
@property(nonatomic, retain) NSDictionary *objectToSend;
@property(nonatomic, retain) NSMutableArray *messageArray;
@property(nonatomic, retain) NSTimer *overlayTimer;
@property(nonatomic, assign) BOOL isFlipped;

- (void)showOverlayView:(NSString *)prompt reconnect:(BOOL)isReconnect;
- (void)hideOverlayView;
- (void)handleConnectFail;
- (void)doShowOverlayView:(NSTimer *)aTimer;
- (void)showMessageSendOverlay;
- (void)hideMessageSendOverlay;

@end

@implementation HSKMainViewController

@synthesize lastMessage, lastPeer, frontButton, objectToSend, messageArray, overlayTimer, isFlipped, adView, adController, customAdController;

#pragma mark -
#pragma mark FlipView Functions 


-(IBAction)flipView
{
    self.isFlipped = YES;
    
	userBusy = YES;
	[flipsideController refreshOwnerData];
	[UIView beginAnimations:@"flip" context:NULL];
    [UIView setAnimationDuration:0.75]; // 0.75 is recommended by Apple. Don't touch!
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
    
	[self.view addSubview: flipView];
    [frontView removeFromSuperview];
	self.navigationItem.title = @"Settings";

	[UIView commitAnimations];
    
    [UIView beginAnimations:@"flip-button" context:NULL];
    [UIView setAnimationDuration:0.75]; // 0.75 is recommended by Apple. Don't touch!
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromRight forView:self.frontButton cache:YES];
    
    [self.frontButton setBackgroundImage:[UIImage imageNamed:@"Done.png"] forState:UIControlStateNormal];
    [self.frontButton addTarget:self action:@selector(flipBack) forControlEvents:UIControlEventTouchUpInside];
    
    [UIView commitAnimations];
}

-(void)flipBack; 
{ 	
    self.isFlipped = NO;
    
	userBusy = NO;
	[UIView beginAnimations:@"flipback" context:NULL];
    [UIView setAnimationDuration:0.75]; // 0.75 is recommended by Apple. Don't touch!
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromLeft forView:self.view cache:YES];
    
	[flipView removeFromSuperview];
    [self.view addSubview:frontView];
	self.navigationItem.title = @"Handshake";

	[UIView commitAnimations];
    
    [UIView beginAnimations:@"button-flipback" context:NULL];
    [UIView setAnimationDuration:0.75]; // 0.75 is recommended by Apple. Don't touch!
    [UIView setAnimationTransition: UIViewAnimationTransitionFlipFromLeft forView:self.frontButton cache:YES];
    [UIView setAnimationDelegate:nil];
	
    [self.frontButton setBackgroundImage:[UIImage imageNamed:@"Wrench.png"] forState:UIControlStateNormal];
    [self.frontButton addTarget:self action:@selector(flipView) forControlEvents:UIControlEventTouchUpInside];
    
    [UIView commitAnimations];
    
    [self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
}

#pragma mark -
#pragma mark Event handlers


- (IBAction)retryConnection:(id)sender
{
    overlayRetryButton.hidden = YES;
    
    if ([[RPSNetwork sharedNetwork] connect])
    {
        [self showOverlayView:@"Connecting to the server…" reconnect:NO];
        
    }
    else
    {
        [self handleConnectFail];
    }
}

- (IBAction)helpMe:(id)sender
{
    // FIXME: change to our final video.
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.youtube.com/watch?v=tHeLemcIb3A"]];
}

#pragma mark -
#pragma mark ctor/dtor

-(id) initWithCoder:(NSCoder *)coder
{	
	if(self = [super initWithCoder:coder])
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkLocationUpdated:) name:RSPNetworkLocationChanged object:nil];
        
		self.messageArray = [NSMutableArray array];
        
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
        
        if ([appVersion isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"defaultsVersion"]])
        {
            // Only load defaults if app versions are equal. Otherwise, it's just too dangerous
            if([[NSUserDefaults standardUserDefaults] objectForKey:@"storedMessages"] != nil)
            {
                
                NSArray *data = [NSKeyedUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] objectForKey:@"storedMessages"]];
                self.messageArray =[[data mutableCopy] autorelease];
            }
        }
	}	
	return self;
}

- (void)dealloc 
{
	self.lastMessage = nil;
	self.frontButton = nil;
    self.objectToSend = nil;
	self.messageArray = nil;
    [self.overlayTimer invalidate];
    self.overlayTimer = nil;
    self.adController = nil;
    self.adView = nil;
    self.customAdController = nil;
    
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

#pragma mark -
#pragma mark View Handlers 

- (void)dismissModals
{
    [self dismissModalViewControllerAnimated:YES];	
	[self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	self.view.backgroundColor =[UIColor blackColor];
    
    
	
    self.view.autoresizesSubviews = YES;
    
    self.frontButton = [[[UIButton alloc] initWithFrame:CGRectMake(0,0,50,29)] autorelease];
    [self.frontButton setBackgroundImage:[UIImage imageNamed:@"Wrench.png"] forState:UIControlStateNormal];
    [self.frontButton addTarget:self action:@selector(flipView) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(popToSelf:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.frontButton] autorelease];
    
#ifdef HS_PREMIUM
    
    [adView removeFromSuperview];
    self.adView = nil;
    self.adController = nil;
    
    [customAdController.verticalFlipImageView removeFromSuperview];
    self.customAdController = nil;
    
#else /* !HS_PREMIUM */
    
    adView.opaque = NO;
    adView.backgroundColor = [UIColor clearColor];
    
    [customAdController startAdServing];
    
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
	
    userBusy = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.overlayTimer invalidate];
    self.overlayTimer = nil;
    
	userBusy = YES;
}

- (void)popToSelf:(id)sender
{
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark -
#pragma mark Private methods

- (void)showOverlayView:(NSString *)prompt reconnect:(BOOL)isReconnect
{
    overlayLabel.text = prompt;
    
    if (isReconnect)
    {
        // Setup a timer and show in 3 seconds
        [self.overlayTimer invalidate];
        self.overlayTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(doShowOverlayView:) userInfo:nil repeats:NO];
    }
    else
    {
        // Just do it!
        [self doShowOverlayView:nil];
    }
}

- (void)doShowOverlayView:(NSTimer *)aTimer
{
	 [[Beacon shared] startSubBeaconWithName:@"reconnecting" timeSession:YES];
	
	userBusy = TRUE; //user is considered busy when overlay view is showing.
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    [self.view addSubview:overlayView];
    [self.view bringSubviewToFront:overlayView];
    
    overlayView.frame = self.view.bounds;
    
    [overlayActivityIndicatorView startAnimating];
}

- (void)hideOverlayView
{
	[[Beacon shared] endSubBeaconWithName:@"reconnecting"]; 
    [self performSelector:@selector(doHideOverlayView) withObject:nil afterDelay:2.0];
}

- (void)doHideOverlayView
{
	//guard it against flipside, need to figure out where else this is going to be called
	if(self.isFlipped == NO)
		userBusy = FALSE; //this should be a safe call here, slight chance it may override a true busy flag, will need testing... on plane hard to test
   
	[self.overlayTimer invalidate];
    self.overlayTimer = nil;
    
    [overlayActivityIndicatorView stopAnimating];
    
    [overlayView removeFromSuperview];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)handleConnectFail
{
    [self showOverlayView:@"Connection failed." reconnect:NO];
    [overlayActivityIndicatorView stopAnimating];
    
    overlayRetryButton.hidden = NO;
}


#pragma mark -
#pragma mark Owner Functions
-(void)verifyOwnerCard 
{ 
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *myPhoneNumber = [[[defaults dictionaryRepresentation] objectForKey: @"SBFormattedPhoneNumber"] numericOnly];
	NSString *phoneNumber;
	BOOL foundOwner = FALSE;
	
	NSLog(@"We have retrieved %@ from the device as the primary number", myPhoneNumber);
	
	ABAddressBookRef addressBook = ABAddressBookCreate();
	
	//no entries in AB
	if(ABAddressBookGetPersonCount(addressBook) == 0)
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
															message:@"Welcome to Handshake! To use Handshake, you must first create a card for yourself. Please create a card in the Contacts application." 
														   delegate:self 
												  cancelButtonTitle:@"Quit" 
												  otherButtonTitles: nil];
		alertView.tag = 2;
		[alertView show];
		[alertView release];
		foundOwner = TRUE; //trick system into state we want it in, we are going to exit anyways
	}
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey: @"ownerRecordRef"])
	{
		foundOwner = TRUE;
		ownerRecord = [[NSUserDefaults standardUserDefaults] integerForKey:@"ownerRecordRef"];
		
		ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), ownerRecord);
		
		if(ownerCard == nil)
			foundOwner = FALSE;
		else
			[self ownerFound];
	}
	
	if(!foundOwner)
	{
		
		NSArray *addresses = (NSArray *) ABAddressBookCopyArrayOfAllPeople(addressBook);
		NSInteger addressesCount = [addresses count];
		
		for (int i = 0; i < addressesCount; i++)
		{
			ABRecordRef record = [addresses objectAtIndex:i];
			NSString *firstName = (NSString *)ABRecordCopyValue(record, kABPersonFirstNameProperty);
			NSString *lastName = (NSString *)ABRecordCopyValue(record, kABPersonLastNameProperty);
			
			NSArray *people = (NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook); 
			
			for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValueAndAutorelease([people objectAtIndex: i] , kABPersonPhoneProperty)) > x); x++)
			{
				//get phone number and strip out anything that isnt a number
				phoneNumber = [(NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease([people objectAtIndex: i] ,kABPersonPhoneProperty) , x) numericOnly];
				
				//compares the phone numbers by suffix incase user is using a 11, 10, or 7 digit number
				if([myPhoneNumber hasSuffix: phoneNumber] && [phoneNumber length] >= 7) //want to make sure we arent testing for numbers that are too short to be real
				{
					UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat: @"Welcome to Handshake! To use Handshake, you must first select your card. If you do not have a card for yourself, please press the Home button and use the Contacts application to create one. We believe you are %@ %@, is this correct?", firstName, lastName] delegate:self cancelButtonTitle:@"No, I Will Select Myself" destructiveButtonTitle:nil otherButtonTitles:[NSString stringWithFormat: @" Yes I am %@", firstName], nil];
					[alert showInView:self.view];
					ownerRecord = ABRecordGetRecordID (record);
					
					alert.tag = 1;
					
					foundOwner = TRUE;
				}
				
				if(foundOwner)
					break;
			}
			
			[firstName release];
			[lastName release];
			
			if(foundOwner)
				break;
		}
		
		if(!foundOwner)
		{
			//unable to find owner, user wil have to select
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Welcome to Handshake! We were unable to determine which card is yours. You will need to select your card before we can begin. If you do not have a card, you will need to create one in the Contacts application." 
                                                           delegate:nil 
                                                  cancelButtonTitle:nil 
                                                  otherButtonTitles:@"Dismiss", nil];
			[alert show];
			[alert release];
			
			primaryCardSelecting = TRUE;
			
			ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
			picker.peoplePickerDelegate = self;
			picker.navigationBarHidden=YES; //gets rid of the nav bar
			
			HSKNavigationController *navController = [[HSKNavigationController alloc] initWithRootViewController:picker];
			navController.navigationBarHidden = YES;
			[self presentModalViewController:navController animated:YES];
			[navController release];
			[picker release];
		}
		
	}
}


- (void)ownerFound
{
	ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), ownerRecord);
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger: ownerRecord forKey:@"ownerRecordRef"];
	
	
	UIImage *avatar;
	
	if([[NSUserDefaults standardUserDefaults] objectForKey: @"avatarData"] == nil)
	{
		avatar = ABPersonHasImageData (ownerCard) ? [UIImage imageWithData: (NSData *)ABPersonCopyImageData(ownerCard)] : [UIImage imageNamed: @"defaultavatar.png"];
	}
	else
	{
		avatar = [UIImage imageWithData: [[NSUserDefaults standardUserDefaults] objectForKey: @"avatarData"]];
	}
	
	[[RPSNetwork sharedNetwork] setDelegate:self];
	RPSNetwork *network = [RPSNetwork sharedNetwork];
	
	
	if([[NSUserDefaults standardUserDefaults] stringForKey: @"ownerNameString"] != nil)
	{
		network.handle = [[NSUserDefaults standardUserDefaults] stringForKey: @"ownerNameString"] ;
	}
	else
	{
		//nil guards
		if((NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonFirstNameProperty) != nil && (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonLastNameProperty) != nil)
			network.handle = [NSString stringWithFormat:@"%@ %@", (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonFirstNameProperty),(NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonLastNameProperty)];
		else if((NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonFirstNameProperty) != nil)
			network.handle = (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonFirstNameProperty);
		else if((NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonLastNameProperty) != nil)
			network.handle = (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonLastNameProperty);
		else
			network.handle = (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonOrganizationProperty);
	}
	
	//network.bot = TRUE;
    network.avatarData = UIImagePNGRepresentation([avatar thumbnail:CGSizeMake(64.0, 64.0)]);	
    
    // Occlude the UI.
    [self showOverlayView:@"Connecting to the server…" reconnect:NO];
    
    if ([[RPSNetwork sharedNetwork] isConnected])
    {
        [[RPSNetwork sharedNetwork] disconnect];
    }
    
    if (![[RPSNetwork sharedNetwork] connect])
    {
        [self handleConnectFail];
    }
}


#pragma mark -
#pragma mark Send & Receive 

//This function will format and return a valid vCard
-(void)formatForVcard:(NSDictionary *)VcardDictionary
{
/* Not going to make the cut into 1.0, save for 1.1
 
	//vCards feel the need
	int itemRunningCount = 1;
	
	//dont forget to remove first line return newb!
	NSString *formattedVcard = @"BEGIN:VCARD\nVERSION:3.0\n";
	
	//name formatters for both "N" and "FN"
	if([VcardDictionary objectForKey: @"FirstName"] != nil || [VcardDictionary objectForKey: @"LastName"] != nil || [VcardDictionary objectForKey: @"MiddleName"] != nil)
	{
		//we have a name lets prefix it
		formattedVcard = [formattedVcard stringByAppendingString:@"N:"];
		
		if([VcardDictionary objectForKey: @"LastName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@;", [VcardDictionary objectForKey: @"LastName"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
		if([VcardDictionary objectForKey: @"FirstName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@;", [VcardDictionary objectForKey: @"FirstName"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
		if([VcardDictionary objectForKey: @"MiddleName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@;", [VcardDictionary objectForKey: @"MiddleName"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
		if([VcardDictionary objectForKey: @"Prefix"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@;", [VcardDictionary objectForKey: @"Prefix"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
		if([VcardDictionary objectForKey: @"Suffix"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@\n", [VcardDictionary objectForKey: @"Suffix"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
		
		
		//formatted name header
		formattedVcard = [formattedVcard stringByAppendingString:@"FN:"];
		
		if([VcardDictionary objectForKey: @"Prefix"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@ ", [VcardDictionary objectForKey: @"Prefix"]]];
		if([VcardDictionary objectForKey: @"FirstName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@ ", [VcardDictionary objectForKey: @"FirstName"]]];
		if([VcardDictionary objectForKey: @"MiddleName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@ ", [VcardDictionary objectForKey: @"MiddleName"]]];
		if([VcardDictionary objectForKey: @"LastName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@ ", [VcardDictionary objectForKey: @"LastName"]]];
		if([VcardDictionary objectForKey: @"Suffix"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString:[NSString stringWithFormat:@"%@\n", [VcardDictionary objectForKey: @"Suffix"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
	}
	
	//nickname
	if([VcardDictionary objectForKey: @"Nickname"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"NICKNAME: %@\n", [VcardDictionary objectForKey: @"Nickname"]]];
	
	//maiden name -- We be fucked for now, will look at later
	
	//ORG
	if([VcardDictionary objectForKey: @"OrgName"] != nil || [VcardDictionary objectForKey: @"Department"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString: @"ORG:"];
		
		if([VcardDictionary objectForKey: @"OrgName"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"%@;", [VcardDictionary objectForKey: @"OrgName"]]];
		else
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([VcardDictionary objectForKey: @"Department"] != nil)
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"%@", [VcardDictionary objectForKey: @"Department"]]];
		
		formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
	}
	
	//job title
	if([VcardDictionary objectForKey: @"JobTitle"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"TITLE:%@\n", [VcardDictionary objectForKey: @"JobTitle"]]];
	
	//vCards do not support user images - gonna have to forfit them
	
	
	//EMAIL Handlers
	if([VcardDictionary objectForKey: @"*EMAIL_$!<Home>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"EMAIL;type=INTERNET;type=HOME:%@\n", [VcardDictionary objectForKey: @"*EMAIL_$!<Home>!$_"]]];
	if([VcardDictionary objectForKey: @"*EMAIL_$!<Work>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"EMAIL;type=INTERNET;type=WORK:%@\n", [VcardDictionary objectForKey: @"*EMAIL_$!<Work>!$_"]]];
	if([VcardDictionary objectForKey: @"*EMAIL_$!<Other>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.EMAIL;type=INTERNET:%@\nitem%i.X-ABLabel:_$!<Other>!$_\n", itemRunningCount, [VcardDictionary objectForKey: @"*EMAIL_$!<Other>!$_"], itemRunningCount]];
		itemRunningCount++;
	}
	
	//Custom Email Handlers
	for(int x = 0; x < [[VcardDictionary allKeys] count]; x++)
	{			
		if([[[VcardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[VcardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*EMAIL"])
		{
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.EMAIL;type=INTERNET:%@\nitem%i.X-ABLabel:%@\n", itemRunningCount,  [VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]], itemRunningCount, [[[VcardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*EMAIL" withString: @""]]];
			itemRunningCount++;
		}
	}
	
	if([VcardDictionary objectForKey: @"*PHONE_$!<Home>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=HOME:%@\n", [VcardDictionary objectForKey: @"*PHONE_$!<Home>!$_"]]];
	if([VcardDictionary objectForKey: @"*PHONE_$!<Work>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=WORK:%@\n", [VcardDictionary objectForKey: @"*PHONE_$!<Work>!$_"]]];
	if([VcardDictionary objectForKey: @"*PHONE_$!<Mobile>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=CELL:%@\n", [VcardDictionary objectForKey: @"*PHONE_$!<Mobile>!$_"]]];
	if([VcardDictionary objectForKey: @"*PHONE_$!<Main>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=MAIN:%@\n", [VcardDictionary objectForKey: @"*PHONE_$!<Main>!$_"]]];
	if([VcardDictionary objectForKey: @"*PHONE_$!<WorkFAX>!$_"] != nil)		
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=WORK;type=FAX:%@\n", [VcardDictionary objectForKey: @"*PHONE_$!<WorkFAX>!$_"]]];
	if([VcardDictionary objectForKey: @"*PHONE_$!<Pager>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=PAGER:%@\n", [VcardDictionary objectForKey: @"*PHONE_$!<Pager>!$_"]]];
	if([VcardDictionary objectForKey: @"*PHONE_$!<HomeFAX>!$_"] != nil)		
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"TEL;type=WORK;type=FAX:%@\n", [VcardDictionary objectForKey: @"*PHONE_$!<HomeFAX>!$_"]]];
	if([VcardDictionary objectForKey: @"*PHONE_$!<Other>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.TEL:%@\nitem%i.X-ABLabel:_$!<Other>!$_\n", itemRunningCount, [VcardDictionary objectForKey: @"*PHONE_$!<Other>!$_"], itemRunningCount]];
		itemRunningCount++;
	}
	
	for(int x = 0; x < [[VcardDictionary allKeys] count]; x++)
	{
		if([[[VcardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[VcardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*PHONE"])
		{
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.TEL:%@\nitem%i.X-ABLabel:%@\n", itemRunningCount, [VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]], itemRunningCount, [[[VcardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*PHONE" withString: @""]]];
			itemRunningCount++;
		}
	}
	
	//address handler HOME
	if([VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item7.ADR;type=HOME:;;"]];
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"Street"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"Street"]];
		}
			
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
			
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"City"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"City"]];
		}
				
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
				
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"State"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"State"]];
		}
			
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
				
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"ZIP"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"ZIP"]];
		}
				
		formattedVcard = [formattedVcard stringByAppendingString: @";\n"];
				
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"CountryCode"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABADR:", itemRunningCount]];
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"CountryCode"]];
			itemRunningCount++;
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
		}
	}
	
	//address handler Work
	if([VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item7.ADR;type=WORK:;;"]];
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"Street"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"Street"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"City"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"City"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"State"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"State"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"ZIP"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"ZIP"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";\n"];
		
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"CountryCode"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABADR:", itemRunningCount]];
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"CountryCode"]];
			itemRunningCount++;
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
		}
	}
	
	//address handler Other -- Needs custom label
	if([VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item7.ADR;type=HOME:;;"]]; //all custom flags will be defined as home, we catch these with the label gaurd
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"Street"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"Street"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"City"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"City"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"State"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"State"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";"];
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"ZIP"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"ZIP"]];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: @";\n"];
		
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"CountryCode"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABADR:", itemRunningCount]];
			formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"CountryCode"]];
			itemRunningCount++;
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
		}
	}
	
	

		
	
	 ADDRESS BE FUCKED: {
	 City = Scottsdale;
	 CountryCode = us;
	 State = AZ;
	 Street = "17030 N 49th Street\n#3173";
	 ZIP = 85254;
	 }
	 
	 item7.ADR;type=HOME:;;17030 N 49th Street;Scottsdale;AZ;85254;USA
	 item7.X-ABLabel:_$!<Other>!$_
	 item7.X-ABADR:us
	 
	 
	 item5.ADR;type=WORK;type=pref:;;123 Fake Street;Scottsdale;AZ;85254;USA
	 item5.X-ABADR:us
	 
	 
	 item6.ADR;type=HOME:;;13 Crossbrook Rd;Newtown;CT;06470;USA
	 item6.X-ABADR:us

	 item8.ADR;type=HOME:;;1 Main Street;FakeTown;UI;87121;USA
	 item8.X-ABLabel:Custom Address
	 item8.X-ABADR:us
	 
	
	//end tag for vCard
	formattedVcard = [formattedVcard stringByAppendingString:@"END:VCARD"];
	//[formattedVcard writeToFile:@"test.vcf" atomically:NO ];
	NSLog(@"%@", formattedVcard);
	
*/	
}

-(void)recievedVCard: (NSDictionary *)vCardDictionary
{
	[[Beacon shared] startSubBeaconWithName:@"cardrecieved" timeSession:NO];

	BOOL specialData = FALSE;
	userBusy = TRUE;
	
	NSError *error = nil;
	
	NSDictionary *incomingData = vCardDictionary;
	NSDictionary *VcardDictionary = [incomingData objectForKey: @"data"]; 
	
	//[self formatForVcard: VcardDictionary];
	
	if(!VcardDictionary || error)
	{
		NSLog(@"%@", [error localizedDescription]);
	}
	else
	{		
		CFErrorRef *ABError = NULL;
		ABRecordRef newPerson = ABPersonCreate();
		
		//ADDRESS HANDLERS
		ABMutableMultiValueRef addressMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(addressMultiValue, [VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"], kABHomeLabel, NULL);
		if([VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(addressMultiValue, [VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"], kABWorkLabel, NULL);
		if([VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(addressMultiValue, [VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"], kABOtherLabel, NULL);
		
		
		for(int x = 0; x < [[VcardDictionary allKeys] count]; x++)
		{			
			if([[[VcardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[VcardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*ADDRESS"])
			{
				ABMultiValueAddValueAndLabel(addressMultiValue, [VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[VcardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*ADDRESS" withString: @""] , NULL);	
			}
		}
		
		
		ABRecordSetValue(newPerson, kABPersonAddressProperty, addressMultiValue, ABError);
        if (addressMultiValue) CFRelease(addressMultiValue);
		
		//IM HANDLERS
		ABMutableMultiValueRef IMMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([VcardDictionary objectForKey: @"*IM_$!<Home>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(IMMultiValue, [VcardDictionary objectForKey: @"*IM_$!<Home>!$_"], kABHomeLabel, NULL);
			specialData = TRUE;
		}
		if([VcardDictionary objectForKey: @"*IM_$!<Work>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(IMMultiValue, [VcardDictionary objectForKey: @"*IM_$!<Work>!$_"], kABWorkLabel, NULL);
			specialData = TRUE;
		}
		if([VcardDictionary objectForKey: @"*IM_$!<Other>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(IMMultiValue, [VcardDictionary objectForKey: @"*IM_$!<Other>!$_"], kABOtherLabel, NULL);
			specialData = TRUE;
		}
		
		
		for(int x = 0; x < [[VcardDictionary allKeys] count]; x++)
		{			
			if([[[VcardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[VcardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*IM"])
			{
				ABMultiValueAddValueAndLabel(IMMultiValue, [VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[VcardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*IM" withString: @""] , NULL);	
				specialData = TRUE;
			}
		}
		
		
		ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, IMMultiValue, ABError);
        if (IMMultiValue) CFRelease(IMMultiValue);
		
		//EMAIL BUTTON
		ABMutableMultiValueRef emailMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([VcardDictionary objectForKey: @"*EMAIL_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(emailMultiValue, [VcardDictionary objectForKey: @"*EMAIL_$!<Home>!$_"], kABHomeLabel, NULL);
		if([VcardDictionary objectForKey: @"*EMAIL_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(emailMultiValue, [VcardDictionary objectForKey: @"*EMAIL_$!<Work>!$_"], kABWorkLabel, NULL);
		if([VcardDictionary objectForKey: @"*EMAIL_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(emailMultiValue, [VcardDictionary objectForKey: @"*EMAIL_$!<Other>!$_"], kABOtherLabel, NULL);
		
		for(int x = 0; x < [[VcardDictionary allKeys] count]; x++)
		{			
			if([[[VcardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[VcardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*EMAIL"])
			{
				ABMultiValueAddValueAndLabel(emailMultiValue, [VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[VcardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*EMAIL" withString: @""] , NULL);	
			}
		}
		
		ABRecordSetValue(newPerson, kABPersonEmailProperty, emailMultiValue, ABError);
        if (emailMultiValue) CFRelease(emailMultiValue);
		
		//RELATED HANDLERS
		ABMutableMultiValueRef relatedMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([VcardDictionary objectForKey: @"*RELATED_$!<Mother>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"*RELATED_$!<Mother>!$_"], kABPersonMotherLabel, NULL);
			specialData = TRUE;
		}
		if([VcardDictionary objectForKey: @"*RELATED_$!<Father>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"*RELATED_$!<Father>!$_"], kABPersonFatherLabel, NULL);
			specialData = TRUE;
		}
		if([VcardDictionary objectForKey: @"*RELATED_$!<Parent>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"*RELATED_$!<Parent>!$_"], kABPersonParentLabel, NULL);
			specialData = TRUE;
		}
		if([VcardDictionary objectForKey: @"*RELATED_$!<Sister>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"*RELATED_$!<Sister>!$_"], kABPersonSisterLabel, NULL);
			specialData = TRUE;
		}
		if([VcardDictionary objectForKey: @"*RELATED_$!<Brother>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"*RELATED_$!<Brother>!$_"], kABPersonBrotherLabel, NULL);
			specialData = TRUE;
		}
		if([VcardDictionary objectForKey: @"*RELATED_$!<Child>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"*RELATED_$!<Child>!$_"], kABPersonChildLabel, NULL);
			specialData = TRUE;
		}
		if([VcardDictionary objectForKey: @"*RELATED_$!<Friend>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"*RELATED_$!<Friend>!$_"], kABPersonFriendLabel, NULL);
			specialData = TRUE;
		}
		if([VcardDictionary objectForKey: @"*RELATED_$!<Partner>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"*RELATED_$!<Partner>!$_"], kABPersonPartnerLabel, NULL);
			specialData = TRUE;
		}
		if([VcardDictionary objectForKey: @"*RELATED_$!<Manager>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"*RELATED_$!<Manager>!$_"], kABPersonManagerLabel, NULL);
			specialData = TRUE;
		}
		if([VcardDictionary objectForKey: @"*RELATED_$!<Assistant>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"*RELATED_$!<Assistant>!$_"], kABPersonAssistantLabel, NULL);
			specialData = TRUE;
		}
		if([VcardDictionary objectForKey: @"*RELATED_$!<Spouse>!$_"] != nil)
		{
			ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: @"*RELATED_$!<Spouse>!$_"], kABPersonSpouseLabel, NULL);
			specialData = TRUE;
		}
		
		
		for(int x = 0; x < [[VcardDictionary allKeys] count]; x++)
		{			
			if([[[VcardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[VcardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*RELATED"])
			{
				ABMultiValueAddValueAndLabel(relatedMultiValue, [VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[VcardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*RELATED" withString: @""] , NULL);	
				specialData = TRUE;
			}
		}
		
		
		ABRecordSetValue(newPerson, kABPersonRelatedNamesProperty, relatedMultiValue, ABError);
        if (relatedMultiValue) CFRelease(relatedMultiValue);
		
		//PHONE HANDLERS
		ABMutableMultiValueRef phoneMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([VcardDictionary objectForKey: @"*PHONE_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: @"*PHONE_$!<Home>!$_"], kABHomeLabel, NULL);
		if([VcardDictionary objectForKey: @"*PHONE_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: @"*PHONE_$!<Work>!$_"], kABWorkLabel, NULL);
		if([VcardDictionary objectForKey: @"*PHONE_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: @"*PHONE_$!<Other>!$_"], kABOtherLabel, NULL);
		if([VcardDictionary objectForKey: @"*PHONE_$!<Mobile>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: @"*PHONE_$!<Mobile>!$_"], kABPersonPhoneMobileLabel, NULL);
		if([VcardDictionary objectForKey: @"*PHONE_$!<Main>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: @"*PHONE_$!<Main>!$_"], kABPersonPhoneMainLabel, NULL);
		if([VcardDictionary objectForKey: @"*PHONE_$!<WorkFAX>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: @"*PHONE_$!<WorkFAX>!$_"], kABPersonPhoneWorkFAXLabel, NULL);
		if([VcardDictionary objectForKey: @"*PHONE_$!<Pager>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: @"*PHONE_$!<Pager>!$_"], kABPersonPhonePagerLabel, NULL);
		if([VcardDictionary objectForKey: @"*PHONE_$!<HomeFAX>!$_"] != nil)
			ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: @"*PHONE_$!<HomeFAX>!$_"], kABPersonPhoneHomeFAXLabel, NULL);
		
		
		for(int x = 0; x < [[VcardDictionary allKeys] count]; x++)
		{			
			if([[[VcardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[VcardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*PHONE"])
			{
				ABMultiValueAddValueAndLabel(phoneMultiValue, [VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[VcardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*PHONE" withString: @""] , NULL);	
			}
		}
		
		ABRecordSetValue(newPerson, kABPersonPhoneProperty, phoneMultiValue, ABError);
        if (phoneMultiValue) CFRelease(phoneMultiValue);
		
		//URL HANDLERS
		ABMutableMultiValueRef URLMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([VcardDictionary objectForKey: @"*URL_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [VcardDictionary objectForKey: @"*URL_$!<Home>!$_"], kABHomeLabel, NULL);
		if([VcardDictionary objectForKey: @"*URL_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [VcardDictionary objectForKey: @"*URL_$!<Work>!$_"], kABWorkLabel, NULL);
		if([VcardDictionary objectForKey: @"*URL_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [VcardDictionary objectForKey: @"*URL_$!<Other>!$_"], kABOtherLabel, NULL);
		if([VcardDictionary objectForKey: @"*URL_$!<HomePage>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [VcardDictionary objectForKey: @"*URL_$!<HomePage>!$_"], kABPersonHomePageLabel, NULL);	
		
		
		for(int x = 0; x < [[VcardDictionary allKeys] count]; x++)
		{			
			if([[[VcardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[VcardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*URL"])
			{
				ABMultiValueAddValueAndLabel(URLMultiValue, [VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[VcardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*URL" withString: @""] , NULL);	
			}
		}
		
		ABRecordSetValue(newPerson, kABPersonURLProperty, URLMultiValue, ABError);
        if (URLMultiValue) CFRelease(URLMultiValue);
		
		//Date HANDLERS
		ABMutableMultiValueRef DateMultiValue =  ABMultiValueCreateMutable(kABStringPropertyType);
		if([VcardDictionary objectForKey: @"*DATE_$!<Home>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [VcardDictionary objectForKey: @"*DATE_$!<Home>!$_"], kABHomeLabel, NULL);
		if([VcardDictionary objectForKey: @"*DATE_$!<Work>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [VcardDictionary objectForKey: @"*DATE_$!<Work>!$_"], kABWorkLabel, NULL);
		if([VcardDictionary objectForKey: @"*DATE_$!<Other>!$_"] != nil)
			ABMultiValueAddValueAndLabel(URLMultiValue, [VcardDictionary objectForKey: @"*DATE_$!<Other>!$_"], kABOtherLabel, NULL);		
		
		
		for(int x = 0; x < [[VcardDictionary allKeys] count]; x++)
		{			
			if([[[VcardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[VcardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*DATE"])
			{
				ABMultiValueAddValueAndLabel(URLMultiValue, [VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]],  (CFStringRef)[[[VcardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*DATE" withString: @""] , NULL);	
			}
		}
		
		ABRecordSetValue(newPerson, kABPersonDateProperty, DateMultiValue, ABError);
        if (DateMultiValue) CFRelease(DateMultiValue);
		
		
		ABRecordSetValue(newPerson, kABPersonFirstNameProperty, [VcardDictionary objectForKey: @"FirstName"], ABError);
		ABRecordSetValue(newPerson, kABPersonLastNameProperty, [VcardDictionary objectForKey: @"LastName"], ABError);
		ABRecordSetValue(newPerson, kABPersonMiddleNameProperty, [VcardDictionary objectForKey: @"MiddleName"], ABError);
		ABRecordSetValue(newPerson, kABPersonOrganizationProperty, [VcardDictionary objectForKey: @"OrgName"], ABError);
		ABRecordSetValue(newPerson, kABPersonJobTitleProperty, [VcardDictionary objectForKey: @"JobTitle"], ABError);
		ABRecordSetValue(newPerson, kABPersonDepartmentProperty, [VcardDictionary objectForKey: @"Department"], ABError);
		ABRecordSetValue(newPerson, kABPersonPrefixProperty, [VcardDictionary objectForKey: @"Prefix"], ABError);
		ABRecordSetValue(newPerson, kABPersonSuffixProperty, [VcardDictionary objectForKey: @"Suffix"], ABError);
		ABRecordSetValue(newPerson, kABPersonNicknameProperty, [VcardDictionary objectForKey: @"Nickname"], ABError);
		ABPersonSetImageData (newPerson, (CFDataRef)[NSData decodeBase64ForString: [VcardDictionary objectForKey: @"contactImage"]], ABError);
		
		NSDate *today = [[NSDate alloc] init];
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"MM-dd-yyyy"];
		
		if([VcardDictionary objectForKey: @"NotesText"] != nil)
		{
			ABRecordSetValue(newPerson, kABPersonNoteProperty, [[VcardDictionary objectForKey: @"NotesText"] stringByAppendingString: [NSString stringWithFormat: @"\n*This contact was sent through Handshake by %@ on %@", lastPeerHandle, [dateFormatter stringFromDate:today]]], ABError);
		}
		else
		{
			ABRecordSetValue(newPerson, kABPersonNoteProperty, [NSString stringWithFormat: @"*This contact was sent through Handshake by %@ on %@", lastPeerHandle, [dateFormatter stringFromDate:today] ], ABError);
		}
		
		[dateFormatter release];
		[today release];
		
		
		HSKUnknownPersonViewController *unknownPersonViewController = [[HSKUnknownPersonViewController alloc] init];
		unknownPersonViewController.unknownPersonViewDelegate = self;
		unknownPersonViewController.addressBook = ABAddressBookCreate();
		unknownPersonViewController.displayedPerson = newPerson;
		unknownPersonViewController.allowsActions = NO;
		unknownPersonViewController.allowsAddingToAddressBook = YES;
		
        HSKNavigationController *navController = [[HSKNavigationController alloc] initWithRootViewController:unknownPersonViewController];
        [self presentModalViewController: navController animated:YES];
        [navController release];
		
		[unknownPersonViewController release];
		
		if(specialData)
		{
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
																message:@"This card contains additional details that the device will not display. To view the entire card sync it back to your computer." 
															   delegate:nil 
													  cancelButtonTitle:nil 
													  otherButtonTitles:@"Dismiss",nil];
			[alertView show];
			[alertView release];
		}
			
	}
}

- (void)sendMyVcard:(BOOL)isBounce
{	
	ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), ownerRecord);
	NSMutableDictionary *VcardDictionary = [[NSMutableDictionary alloc] init];
	
	//single value objects
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonFirstNameProperty) forKey: @"FirstName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonMiddleNameProperty) forKey: @"MiddleName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonLastNameProperty) forKey: @"LastName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonOrganizationProperty) forKey: @"OrgName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonJobTitleProperty) forKey: @"JobTitle"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonDepartmentProperty) forKey: @"Department"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonPrefixProperty) forKey: @"Prefix"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonSuffixProperty) forKey: @"Suffix"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonNicknameProperty) forKey: @"Nickname"];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey: @"allowNote"])
		[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonNoteProperty) forKey: @"NotesText"];
    
    // Re-encode the image
    UIImage *contactImage = [UIImage imageWithData:(NSData *)ABPersonCopyImageData(ownerCard)];
    if (contactImage)
    {
        [VcardDictionary setValue: [UIImageJPEGRepresentation(contactImage, 0.5) encodeBase64ForData] forKey: @"contactImage"];
    }
    else
    {
        [VcardDictionary setValue: nil forKey: @"contactImage"];
    }
    

	//phone
    CFTypeRef abValue = ABRecordCopyValue(ownerCard , kABPersonPhoneProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonPhoneProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*PHONE%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonPhoneProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//email
    abValue = ABRecordCopyValue(ownerCard , kABPersonEmailProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonEmailProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*EMAIL%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonEmailProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//address
    abValue = ABRecordCopyValue(ownerCard , kABPersonAddressProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonAddressProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*ADDRESS%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonAddressProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//URLs
    abValue = ABRecordCopyValue(ownerCard , kABPersonURLProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonURLProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*URL%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonURLProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//IM
    abValue = ABRecordCopyValue(ownerCard , kABPersonInstantMessageProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonInstantMessageProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*IM%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonInstantMessageProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//dates
    abValue = ABRecordCopyValue(ownerCard , kABPersonDateProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		//need to convert to string to play nice with JSON
		[VcardDictionary setValue: [(NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonDateProperty) , x) description] 
						   forKey: [NSString stringWithFormat: @"*DATE%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonDateProperty) , x)]];		
	}
    if (abValue) CFRelease(abValue);
	
	//relatives
    abValue = ABRecordCopyValue(ownerCard , kABPersonRelatedNamesProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonRelatedNamesProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*RELATED%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonRelatedNamesProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
    
	
	NSMutableDictionary *completedDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
	[completedDictionary setValue:VcardDictionary forKey:@"data"];
	[completedDictionary setValue: @"1.0" forKey:@"version"];
	if (isBounce)
    {
        [completedDictionary setValue: @"vcard_bounced" forKey:@"type"];
    }
    else
    {
        [completedDictionary setValue: @"vcard" forKey:@"type"];
    }
		
	self.objectToSend = completedDictionary;

    if (!isBounce)
    {
		[[Beacon shared] startSubBeaconWithName:@"mycardsent" timeSession:NO];

        RPSBrowserViewController *browserViewController = [[RPSBrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
        HSKNavigationController *navController = [[HSKNavigationController alloc] initWithRootViewController:browserViewController];
        browserViewController.navigationItem.prompt = @"Select a Recipient";
        browserViewController.delegate = self;
        browserViewController.defaultAvatar = [UIImage imageNamed:@"defaultavatar.png"];
        browserViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModals)] autorelease];
        [self.navigationController presentModalViewController:navController animated:YES];
        [browserViewController release];	
        [navController release];
	}
    else
    {
		[[Beacon shared] startSubBeaconWithName:@"cardbounced" timeSession:NO];

        RPSNetwork *network = [RPSNetwork sharedNetwork];
        [network sendMessage: objectToSend toPeer: lastPeer compress:YES];
    }
    
	[completedDictionary release];
}

- (void)sendOtherVcard:(ABPeoplePickerNavigationController *)picker
{
	[[Beacon shared] startSubBeaconWithName:@"othersent" timeSession:NO];

	
	ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), otherRecord);

	NSMutableDictionary *VcardDictionary = [[NSMutableDictionary alloc] init];
	
	
	//single value objects
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonFirstNameProperty) forKey: @"FirstName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonMiddleNameProperty) forKey: @"MiddleName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonLastNameProperty) forKey: @"LastName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonOrganizationProperty) forKey: @"OrgName"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonJobTitleProperty) forKey: @"JobTitle"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonDepartmentProperty) forKey: @"Department"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonPrefixProperty) forKey: @"Prefix"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonSuffixProperty) forKey: @"Suffix"];
	[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonNicknameProperty) forKey: @"Nickname"];
	
	if([[NSUserDefaults standardUserDefaults] boolForKey: @"allowNote"])
		[VcardDictionary setValue: (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonNoteProperty) forKey: @"NotesText"];
    
	// Re-encode the image
    UIImage *contactImage = [UIImage imageWithData:(NSData *)ABPersonCopyImageData(ownerCard)];
    if (contactImage)
    {
        [VcardDictionary setValue: [UIImageJPEGRepresentation(contactImage, 0.5) encodeBase64ForData] forKey: @"contactImage"];
    }
    else
    {
        [VcardDictionary setValue: nil forKey: @"contactImage"];
    }
	
	//phone
    CFTypeRef abValue = ABRecordCopyValue(ownerCard , kABPersonPhoneProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonPhoneProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*PHONE%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonPhoneProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//email
    abValue = ABRecordCopyValue(ownerCard , kABPersonEmailProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonEmailProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*EMAIL%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonEmailProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//address
    abValue = ABRecordCopyValue(ownerCard , kABPersonAddressProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonAddressProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*ADDRESS%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonAddressProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//URLs
    abValue = ABRecordCopyValue(ownerCard , kABPersonURLProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonURLProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*URL%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonURLProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//IM
    abValue = ABRecordCopyValue(ownerCard , kABPersonInstantMessageProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonInstantMessageProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*IM%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonInstantMessageProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	//dates
    abValue = ABRecordCopyValue(ownerCard , kABPersonDateProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		//need to convert to string to play nice with JSON
		[VcardDictionary setValue: [(NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonDateProperty) , x) description] 
						   forKey: [NSString stringWithFormat: @"*DATE%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonDateProperty) , x)]];		
	}
    if (abValue) CFRelease(abValue);
	
	//relatives
    abValue = ABRecordCopyValue(ownerCard , kABPersonRelatedNamesProperty);
	for (int x = 0; (ABMultiValueGetCount(abValue) > x); x++)
	{
		[VcardDictionary setValue: (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonRelatedNamesProperty) , x) 
						   forKey: [NSString stringWithFormat: @"*RELATED%@", (NSString *)ABMultiValueCopyLabelAtIndex(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonRelatedNamesProperty) , x)]];
	}
    if (abValue) CFRelease(abValue);
	
	NSMutableDictionary *completedDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
	[completedDictionary setValue:VcardDictionary forKey:@"data"];
	[completedDictionary setValue: @"1.0" forKey:@"version"];
	[completedDictionary setValue: @"vcard" forKey:@"type"];
	
	self.objectToSend = completedDictionary;
	
	[[Beacon shared] startSubBeaconWithName:@"searchingpeer" timeSession:YES];

	RPSBrowserViewController *browserViewController = [[RPSBrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
	browserViewController.navigationItem.prompt = @"Select a Peer";
    browserViewController.delegate = self;
    browserViewController.defaultAvatar = [UIImage imageNamed:@"defaultavatar.png"];
    [picker pushViewController:browserViewController animated:YES];
    [browserViewController release];	
	
	[completedDictionary release];
}

-(void)recievedPict:(NSDictionary *)pictDictionary
{	
	[[Beacon shared] startSubBeaconWithName:@"picturereceived" timeSession:NO];

	userBusy = TRUE;
		
	NSDictionary *incomingData = pictDictionary;
	NSData *data = [NSData decodeBase64ForString:[incomingData objectForKey: @"data"]]; 
	
    UIImage *receivedImage = [UIImage imageWithData: data];
    
    HSKPicturePreviewViewController *picPreviewController = [[HSKPicturePreviewViewController alloc] initWithNibName:@"PicturePreviewViewController" bundle:nil];
    [picPreviewController view];
    picPreviewController.pictureImageView.image = receivedImage;
    HSKNavigationController *navController = [[HSKNavigationController alloc] initWithRootViewController:picPreviewController];
    [self presentModalViewController:navController animated:YES];
    [navController release];
    [picPreviewController release];
}

- (void)checkQueueForMessages
{
	if(!userBusy)
	{		
		//if we have a message in queue handle it
		if([self.messageArray count] > 0)
		{
            /*
			if([self.messageArray count]-1 == 1)
			{
				queueNumberLabel.text = @"1 message is waiting";
				queueNumberLabel.hidden = FALSE;

			}
			else if ([self.messageArray count]-1 > 1)
			{
				queueNumberLabel.text = [NSString stringWithFormat:@"%i messages are waiting", [self.messageArray count]-1];
				queueNumberLabel.hidden = FALSE;
			}
			
			else
			{
				queueNumberLabel.hidden = TRUE;
				
			}
            */
			
			
			[self messageReceived:[RPSNetwork sharedNetwork] fromPeer:[[self.messageArray objectAtIndex:0] objectForKey:@"peer"] message:[[self.messageArray objectAtIndex:0] objectForKey:@"message"]];
			
			//done with it so trash it
			[self.messageArray removeObjectAtIndex: 0];
			
		}	
		
		
	} 
}

#pragma mark -
#pragma mark Alerts 


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	
	//boot message to select new owner.
	if (actionSheet.tag == 1)
    {
		if(buttonIndex == 0)
		{
			//we have found the correct user
			primaryCardSelecting = FALSE;
			[self ownerFound];
		}
		
		//we missed the mark for correct owner, user will select
		else if(buttonIndex == 1)
		{
			primaryCardSelecting = TRUE;
			
			ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
			picker.peoplePickerDelegate = self;
			picker.navigationBarHidden=YES; //gets rid of the nav bar
			[self presentModalViewController:picker animated:YES];
			[picker release];
		}
	}
	
	//new card recieved
	if (actionSheet.tag == 2)
    {
		//preview and bounce
		if(buttonIndex == 0)
		{
			[self sendMyVcard:YES];
			[self recievedVCard: lastMessage];
		}
		
		//preview
		else if(buttonIndex == 1)
		{
			[self recievedVCard: lastMessage];
		}
		
		//discard
		else if(buttonIndex == 2)
		{
			//do nothing
			userBusy = FALSE;
		}
		
		[self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
	}
	
	//bounce card recieved
	if (actionSheet.tag == 3)
    {
		if(buttonIndex == 0)
		{
			[self recievedVCard: lastMessage];
		}
		
		else if(buttonIndex == 1)
		{
			//do nothing
			userBusy = FALSE;
		}

		[self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
	}
	
	
	//picture received
	if (actionSheet.tag == 4)
    {
		if(buttonIndex == 0)
		{
			//preview
			[self recievedPict: self.lastMessage];
			
		}
		
		else if(buttonIndex == 1)
		{
			//save without preview
			userBusy = TRUE;
			            
			NSData *data = [NSData decodeBase64ForString:[self.lastMessage objectForKey: @"data"]]; 
						
			UIImageWriteToSavedPhotosAlbum([UIImage imageWithData: data], nil, nil, nil);
		}
		
		else if(buttonIndex == 2)
		{
			//discard Do Nothing
			userBusy = FALSE;
		}
		
		
		[self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{	
	//yes add to our photo album
    if (alertView.tag == 0)
    {
        if(buttonIndex == 1)
        {
            [self recievedPict: self.lastMessage];
        }
    }	
	//no contacts in AB book
	else if (alertView.tag == 2)
    {
		exit(0);
	}

}

#pragma mark -
#pragma mark People Picker Functions


- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker 
{
	userBusy = NO;

	
	[self dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	userBusy = NO;
	
	
	if(primaryCardSelecting)
	{
        [self dismissModalViewControllerAnimated:YES];
        
		ownerRecord = ABRecordGetRecordID(person);
		[self ownerFound];
	}
	else
	{
		otherRecord = ABRecordGetRecordID(person);
		[self sendOtherVcard:peoplePicker];
	}
    
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	//we should never get here anyways
	userBusy = NO;

	
    return NO;
}
#pragma mark -
#pragma mark image picker 


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
	[[Beacon shared] startSubBeaconWithName:@"picturesent" timeSession:NO];

	
	userBusy = NO;
	
    NSData *data = UIImageJPEGRepresentation(image, 0.5);
    
	NSMutableDictionary *completedDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
	[completedDictionary setValue:[data encodeBase64ForData] forKey:@"data"];
	[completedDictionary setValue: @"1.0" forKey:@"version"];
	[completedDictionary setValue: @"img" forKey:@"type"];
	
	self.objectToSend = completedDictionary;
	
	[[Beacon shared] startSubBeaconWithName:@"searchingpeer" timeSession:YES];
	
	RPSBrowserViewController *browserViewController = [[RPSBrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
	browserViewController.navigationItem.prompt = @"Select a Recipient";
    browserViewController.delegate = self;
    browserViewController.defaultAvatar = [UIImage imageNamed:@"defaultavatar.png"];
    [picker pushViewController:browserViewController animated:YES];
    [browserViewController release];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	userBusy = NO;
	[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Table Functions

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kHSKTableHeaderHeight;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @" ";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{

	return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	
	static NSString *MyIdentifier = @"MyIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
	}
	
	if([indexPath section] == 0)
	{
		if([indexPath row] == 0)
		{
			cell.text = @"Send my card";
			[cell setImage:  [UIImage imageNamed: @"vcard.png"]];
		}
		else if ([indexPath row] == 1)
		{
			cell.text = @"Send other card";
			[cell setImage:  [UIImage imageNamed: @"ab.png"]];
		}
		else if ([indexPath row] == 2)
		{
			cell.text = @"Send a picture";
			[cell setImage:  [UIImage imageNamed: @"pict.png"]];
		}
	}
	
		
	//adds the disclose indictator. 
	// cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	// Configure the cell
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	userBusy = YES;
	//do that HIG glow thing that apple likes so much
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
	
	//send my vCard
	if ([indexPath row] == 0)
	{
		[self sendMyVcard:NO];
	}
	
	//send someone elses card
	if ([indexPath row] == 1)
	{
		userBusy = TRUE; //dont want to pop queue when user is looking for someone
		primaryCardSelecting = FALSE;
		ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
		picker.navigationBarHidden=NO;
        [self presentModalViewController:picker animated:YES];
        [picker release];	
	}
	
	if([indexPath row] == 2)
	{
		UIImagePickerController *picker = [[UIImagePickerController alloc] init];
		[picker setDelegate:self];
		picker.navigationBarHidden=YES; 
		
		if([[NSUserDefaults standardUserDefaults] boolForKey: @"allowImageEdit"])
			picker.allowsImageEditing = YES;
		else
			picker.allowsImageEditing = NO;
		
		[self presentModalViewController:picker animated:YES];
        [picker release];	
	}
}

#pragma mark -
#pragma mark RPSNetworkDelegate methods


- (void)connectionFailed:(RPSNetwork *)sender
{
	[[Beacon shared] startSubBeaconWithName:@"connectionfailed" timeSession:NO];
	[self handleConnectFail];
}

- (void)connectionSucceeded:(RPSNetwork *)sender
{
	[[Beacon shared] startSubBeaconWithName:@"connectionsucceed" timeSession:NO];
    [self hideOverlayView];
}

- (void)messageReceived:(RPSNetwork *)sender fromPeer:(RPSNetworkPeer *)peer message:(id)message
{	
	//not a ping lets handle it
    if(![message isEqual:@"PING"])
	{
		NSDictionary *incomingData = message;
		
		if(!userBusy)
		{
			//client sees	
			self.lastMessage = message;
			self.lastPeer = peer;
			lastPeerHandle = peer.handle;
			
			userBusy = TRUE;
			//App will not let user proceed if if is about to post a message but if you hit it spot
			//on it will highlight the row and lock it
			[mainTable deselectRowAtIndexPath: [mainTable indexPathForSelectedRow] animated: YES];
			
			if([[incomingData objectForKey: @"type"] isEqualToString:@"vcard"])
			{
				
				
				UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ has sent you a card", peer.handle]
																   delegate:self
														  cancelButtonTitle:@"Discard"
													 destructiveButtonTitle:nil
														  otherButtonTitles:@"Preview and Exchange", @"Preview" ,  nil];

				alert.tag = 2;
				[alert showInView:self.view];
				[alert release];
			}
			
			//vcard was returned
			else if([[incomingData objectForKey: @"type"] isEqualToString:@"vcard_bounced"])
			{
				UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ has sent you a card in exchange for your card", peer.handle]
																   delegate:self
														  cancelButtonTitle:@"Discard"
													 destructiveButtonTitle:nil
														  otherButtonTitles:@"Preview", nil];
				
				alert.tag = 3;
				[alert showInView:self.view];
				[alert release];
			}
			
			else if([[incomingData objectForKey: @"type"] isEqualToString:@"img"])
			{
				UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@ has sent you a picture", peer.handle]
																   delegate:self
														  cancelButtonTitle:@"Discard"
													 destructiveButtonTitle:nil
														  otherButtonTitles:@"Preview", @"Save to Camera Roll" ,  nil];
				
				alert.tag = 4;
				[alert showInView:self.view];
				[alert release];
			}
		}
		
		else
		{
			[self.messageArray addObject:[NSDictionary dictionaryWithObjectsAndKeys: peer, @"peer", message, @"message", nil]];
		}
	}
}

- (void)connectionWillReactivate:(RPSNetwork *)sender
{
    NSLog(@"Coming out of autolock...");
    [self showOverlayView:@"Connecting to the server…" reconnect:YES];
}


#pragma mark -
#pragma mark RPSBrowserViewControllerDelegate methods

- (void)browserViewController:(RPSBrowserViewController *)sender selectedPeer:(RPSNetworkPeer *)peer
{
	[[Beacon shared] endSubBeaconWithName:@"searchingpeer"];
	
    RPSNetwork *network = [RPSNetwork sharedNetwork];
	
	[self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];

	
    sender.selectedPeer = peer;
    

    [self showMessageSendOverlay];
    
	@try
    {
        [network sendMessage:self.objectToSend toPeer:peer compress:YES];
    }
    @catch(NSException *e)
    {
        NSLog(@"Unable to send message: %@", [e reason]);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" 
                                                        message:@"Unable to the send message. The message was too large." 
                                                       delegate:nil 
                                              cancelButtonTitle:nil 
                                              otherButtonTitles:@"Dismiss", nil];
        [alert show];
        [alert release];
        
        [self hideMessageSendOverlay];
    }
    
    [sender.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)messageSuccess:(RPSNetwork *)sender contextHandle:(NSUInteger)context
{    
    [self hideMessageSendOverlay];
}

- (void)messageFailed:(RPSNetwork *)sender contextHandle:(NSUInteger)context
{
	[[Beacon shared] startSubBeaconWithName:@"messagefailed" timeSession:NO];

	
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Error sending message to the remote device."
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    
    [self hideMessageSendOverlay];
}


#pragma mark -
#pragma mark ABUnknownPersonViewControllerDelegate methods 

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonViewController didResolveToPerson:(ABRecordRef)person 
{
	userBusy = NO;
	[self.navigationController dismissModalViewControllerAnimated: NO];	
}


#pragma mark -
#pragma mark UIViewController methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


#pragma mark -
#pragma mark UIAppicationDelegate methods

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	NSLog(@"Terminate");
	[[NSUserDefaults standardUserDefaults] setObject: [NSKeyedArchiver archivedDataWithRootObject:self.messageArray] forKey:@"storedMessages"];
    
    // Write the app version into the defaults
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"defaultsVersion"];
}

#pragma mark -
#pragma mark RPSNetwork notification methods

- (void)networkLocationUpdated:(NSNotification *)aNotification
{
    CLLocation *location = [[aNotification userInfo] objectForKey:@"location"];
    NSLog(@"updating pinch media's stuff with location: %@", location);
    
    [[Beacon shared] setBeaconLocation:location];
}

#pragma mark - 
#pragma mark Message send UI

- (void)showMessageSendOverlay
{
    [messageSendIndicatorView startAnimating];
    messageSendLabel.hidden = NO;
    messageSendBackground.hidden = NO;
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
}

- (void)hideMessageSendOverlay
{
    [messageSendIndicatorView stopAnimating];
    messageSendLabel.hidden = YES;
    messageSendBackground.hidden = YES;
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

@end
