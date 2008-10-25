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
#import "NSString+SKPURLAdditions.h"
#import "NSURLConnection+SKPAdditions.h"
#import "HSKImageRounding.h"


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
@property(nonatomic, assign) BOOL isShowingOverlayView;
@property(nonatomic, retain) NSDate *lastSoundPlayed;
@property(nonatomic, retain) UIImage *avatarImage;




- (void)showOverlayView:(NSString *)prompt reconnect:(BOOL)isReconnect;
- (void)hideOverlayView;
- (void)handleConnectFail;
- (void)doShowOverlayView:(NSTimer *)aTimer;
- (void)showMessageSendOverlay;
- (void)hideMessageSendOverlay;
- (void)showShareButton;
- (void)hideShareButton;

@end

@implementation HSKMainViewController

@synthesize lastMessage, lastPeer, frontButton, objectToSend, messageArray, overlayTimer, isFlipped, adView, adController, customAdController, lastSoundPlayed, isShowingOverlayView, avatarImage;

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
	userBusy = FALSE;
	
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

- (IBAction)sendSMS:(id)sender
{
    userBusy = TRUE;
    
    HSKSMSModalViewController *smsController = [[HSKSMSModalViewController alloc] init];
    smsController.delegate = self;
    HSKNavigationController *navController = [[HSKNavigationController alloc] initWithRootViewController:smsController];
    [self.navigationController presentModalViewController:navController animated:YES];
    [navController release];
    [smsController release];
    
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
            NSLog(@"matching defaults version");
            // Only load defaults if app versions are equal. Otherwise, it's just too dangerous
            if([[NSUserDefaults standardUserDefaults] objectForKey:@"storedMessages"] != nil)
            {
                NSArray *data = [NSKeyedUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] objectForKey:@"storedMessages"]];
                self.messageArray =[[data mutableCopy] autorelease];
                
                NSLog(@"messageArray: %@", messageArray);
                
                [self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
            }
        }
        else
        {
            NSLog(@"non-matching defaults version");
        }
		
		send = [[HSKSoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sent" ofType:@"caf"]];
		receive = [[HSKSoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"receive" ofType:@"caf"]];
		self.lastSoundPlayed = [NSDate date];
		
		//respect the silent toggle!
		AudioSessionInitialize(nil, nil, nil, nil);
		UInt32	sessionCategory = kAudioSessionCategory_AmbientSound;
		AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
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
	self.lastSoundPlayed = nil;
	self.avatarImage = nil;
	
	
	[send dealloc];
	[receive dealloc];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

#pragma mark -
#pragma mark View Handlers 

- (void)dismissModals
{
    [self dismissModalViewControllerAnimated:YES];	
	userBusy = FALSE;
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
    
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"Back nav bar button") style:UIBarButtonItemStyleBordered target:self action:@selector(popToSelf:)] autorelease];
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
	
	[self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
	
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    NSLog(@"TIMER: Killing overlay timer");
    [self.overlayTimer invalidate];
    self.overlayTimer = nil;
    
	userBusy = YES;
}

- (void)popToSelf:(id)sender
{
    [self.navigationController popToViewController:self animated:YES];
	[self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
}

#pragma mark -
#pragma mark Private methods

- (void)showOverlayView:(NSString *)prompt reconnect:(BOOL)isReconnect
{
    overlayLabel.text = prompt;
    
    if (isReconnect)
    {
        // Setup a timer and show in 2 seconds
        NSLog(@"TIMER: Arming overlay timer");
        [self.overlayTimer invalidate];
        self.overlayTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(doShowOverlayView:) userInfo:nil repeats:NO];
    }
    else
    {
        // Just do it!
        [self doShowOverlayView:nil];
    }
}

- (void)doShowOverlayView:(NSTimer *)aTimer
{	
    if  (aTimer)
    {
        NSLog(@"TIMER: Overlay timer fired!");
    }
    
    self.isShowingOverlayView = YES;
    
	//Dismiss any modals that are ontop of the connecting overlay
	if(userBusy && self.isFlipped == FALSE)
		[self dismissModalViewControllerAnimated:YES];	
	
	userBusy = TRUE; //user is considered busy when overlay view is showing.
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    [self.view addSubview:overlayView];
    [self.view bringSubviewToFront:overlayView];
    
    
    overlayView.frame = self.view.bounds;
    
    [overlayActivityIndicatorView startAnimating];
}

- (void)hideOverlayView
{    
    [overlayActivityIndicatorView stopAnimating];
    
    [overlayView removeFromSuperview];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    self.isShowingOverlayView = NO;
    
    if(self.isFlipped == NO)
    {
        NSLog(@"clearing userBusy flag in connectionSucceeded");
        userBusy = FALSE; //this should be a safe call here
    }
    
    [self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
}

- (void)showShareButton
{
    // Only show this feature for the US and Canada
    NSString *countryCode = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleCountryCode];
    if ([countryCode isEqualToString:@"US"] || [countryCode isEqualToString:@"CA"])
    {
        UIBarButtonItem *tmpItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Share", @"Share link via SMS button") style:UIBarButtonItemStyleBordered target:self action:@selector(sendSMS:)] autorelease];
        [self.navigationItem setLeftBarButtonItem:tmpItem animated:YES];
    }
}

- (void)hideShareButton
{
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
}

- (void)handleConnectFail
{
    [self showOverlayView:NSLocalizedString(@"Connection failed.", @"Connection failed overlay title") reconnect:NO];
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
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey: @"ownerRecordRef"])
	{
		foundOwner = TRUE;
		ownerRecord = [[NSUserDefaults standardUserDefaults] integerForKey:@"ownerRecordRef"];
		
		ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), ownerRecord);
		
		if(ownerCard == nil)
        {
			foundOwner = FALSE;
        }
		else
        {
			[self ownerFound];
        }
	}
    
    //no entries in AB
	if(ABAddressBookGetPersonCount(addressBook) == 0)
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
															message:NSLocalizedString(@"Welcome to Handshake! To use Handshake, you must first create a card for yourself. Please create a card in the Contacts application.", @"No cards in Address Book alert message") 
														   delegate:self 
												  cancelButtonTitle:NSLocalizedString(@"Quit", @"Quit button title")
												  otherButtonTitles: nil];
		alertView.tag = 2;
		[alertView show];
		[alertView release];
		foundOwner = TRUE; //trick system into state we want it in, we are going to exit anyways
	}
	
	if(!foundOwner)
	{
        time_t startTime = time(NULL);
        NSLog(@"Starting address book iteration...");
        
        NSArray *addresses = (NSArray *) ABAddressBookCopyArrayOfAllPeople(addressBook);
        NSInteger addressesCount = [addresses count];
        
        for (int i = 0; i < addressesCount; i++)
        {
            ABRecordRef record = [addresses objectAtIndex:i];
            NSString *firstName = (NSString *)ABRecordCopyValue(record, kABPersonFirstNameProperty);
            NSString *lastName = (NSString *)ABRecordCopyValue(record, kABPersonLastNameProperty);
                            
            for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValueAndAutorelease([addresses objectAtIndex: i] , kABPersonPhoneProperty)) > x); x++)
            {
                //get phone number and strip out anything that isnt a number
                phoneNumber = [(NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease([addresses objectAtIndex: i] ,kABPersonPhoneProperty) , x) numericOnly];
                
                //compares the phone numbers by suffix incase user is using a 11, 10, or 7 digit number
                if([myPhoneNumber hasSuffix: phoneNumber] && [phoneNumber length] >= 7) //want to make sure we arent testing for numbers that are too short to be real
                {
                    UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Welcome to Handshake! To use Handshake, you must first select your card. If you do not have a card for yourself, please press the Home button and use the Contacts application to create one. We believe you are %@ %@, is this correct?", @"Card detection alert message"), firstName, lastName] 
                                                                       delegate:self 
                                                              cancelButtonTitle:NSLocalizedString(@"No", @"No button title") 
                                                         destructiveButtonTitle:nil 
                                                              otherButtonTitles:[NSString stringWithFormat: NSLocalizedString(@"Yes I am %@", @"Yes button title"), firstName], nil];
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
        
        [addresses release];
        
        NSLog(@"Ended address book iteration, took %d seconds.", time(NULL) - startTime);
		
		if(!foundOwner)
		{
			//unable to find owner, user wil have to select
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" 
                                                            message:NSLocalizedString(@"Welcome to Handshake! We were unable to determine which card is yours. You will need to select your card before we can begin. If you do not have a card, you will need to create one in the Contacts application.", @"Card selection alert message") 
                                                           delegate:nil 
                                                  cancelButtonTitle:nil 
                                                  otherButtonTitles:NSLocalizedString(@"Dismiss", @"Dismiss button title"), nil];
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
	
	network.bot = TRUE;
	
	self.avatarImage = [ImageManipulator makeRoundCornerImage:[avatar thumbnail:CGSizeMake(64.0, 64.0)] :7 :7];
	
	
    network.avatarData = UIImagePNGRepresentation(self.avatarImage);	
    
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
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"NICKNAME:%@\n", [VcardDictionary objectForKey: @"Nickname"]]];
	
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
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.ADR;type=HOME:;;", itemRunningCount]];
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_"] objectForKey:@"Street"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[[VcardDictionary objectForKey: @"*ADDRESS_$!<Home>!$_" ] objectForKey:@"Street"] stringByReplacingOccurrencesOfString: @"\n" withString: @" "]];
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
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:Home\n", itemRunningCount]];
		itemRunningCount++;
	}
	
	//address handler Work
	if([VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.ADR;type=WORK:;;", itemRunningCount]];
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_"] objectForKey:@"Street"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[[VcardDictionary objectForKey: @"*ADDRESS_$!<Work>!$_" ] objectForKey:@"Street"] stringByReplacingOccurrencesOfString: @"\n" withString: @" "]];
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
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
		}
		
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:Work\n", itemRunningCount]];
		itemRunningCount++;
	}
	
	//address handler Other
	if([VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.ADR;type=HOME:;;", itemRunningCount]]; //all custom flags will be defined as home, we catch these with the label gaurd
		
		if([[VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_"] objectForKey:@"Street"] != nil)
		{
			formattedVcard = [formattedVcard stringByAppendingString: [[[VcardDictionary objectForKey: @"*ADDRESS_$!<Other>!$_" ] objectForKey:@"Street"] stringByReplacingOccurrencesOfString: @"\n" withString: @" "]];

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
			formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
		}
		
		
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:Other\n", itemRunningCount]];
		itemRunningCount++;
	}
	
	
	//Address Handle Custom
	for(int x = 0; x < [[VcardDictionary allKeys] count]; x++)
	{			
		if([[[VcardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[VcardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*ADDRESS"])
		{
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.ADR;type=HOME:;;", itemRunningCount]]; //all custom flags will be defined as home, we catch these with the label gaurd
			
			if([[VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]] objectForKey:@"Street"] != nil)
			{
				formattedVcard = [formattedVcard stringByAppendingString: [[[VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]] objectForKey:@"Street"] stringByReplacingOccurrencesOfString: @"\n" withString: @" "]];
			}
			
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
			
			if([[VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]] objectForKey:@"City"] != nil)
			{
				formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]] objectForKey:@"City"]];
			}
			
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
			
			if([[VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]] objectForKey:@"State"] != nil)
			{
				formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]] objectForKey:@"State"]];
			}
			
			formattedVcard = [formattedVcard stringByAppendingString: @";"];
			
			if([[VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]] objectForKey:@"ZIP"] != nil)
			{
				formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]] objectForKey:@"ZIP"]];
			}
			
			formattedVcard = [formattedVcard stringByAppendingString: @";\n"];
			
			
			if([[VcardDictionary objectForKey:[[VcardDictionary allKeys] objectAtIndex: x]] objectForKey:@"CountryCode"] != nil)
			{
				formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABADR:", itemRunningCount]];
				formattedVcard = [formattedVcard stringByAppendingString: [[VcardDictionary objectForKey: [[VcardDictionary allKeys] objectAtIndex: x]] objectForKey:@"CountryCode"]];
				formattedVcard = [formattedVcard stringByAppendingString: @"\n"];
			}
			
			
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:%@\n", itemRunningCount, [[[VcardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*ADDRESS" withString: @""]]];
			itemRunningCount++;
		}
	}
	
	
	//URL Handlers 
	if([VcardDictionary objectForKey: @"*URL_$!<Home>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"URL;type=HOME:%@\n", [VcardDictionary objectForKey: @"*URL_$!<Home>!$_"]]];
	if([VcardDictionary objectForKey: @"*URL_$!<Work>!$_"] != nil)
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"URL;type=WORK:%@\n", [VcardDictionary objectForKey: @"*URL_$!<Work>!$_"]]];
	if([VcardDictionary objectForKey: @"*URL_$!<Other>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.URL:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*URL_$!<Other>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Other>!$_\n", itemRunningCount]];
		itemRunningCount++;
	}
	if([VcardDictionary objectForKey: @"*URL_$!<HomePage>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.URL:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*URL_$!<HomePage>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<HomePage>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	
	for(int x = 0; x < [[VcardDictionary allKeys] count]; x++)
	{			
		if([[[VcardDictionary allKeys] objectAtIndex: x] rangeOfString: @"$!<"].location == NSNotFound && [[[VcardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*URL"])
		{
			formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.URL:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*URL_$!<HomePage>!$_"]]];
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:%@\n", itemRunningCount, [[[VcardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*URL" withString: @""]]]; 
			itemRunningCount++;
		}
	}
	
	//RELATED HANDLERS
	if([VcardDictionary objectForKey: @"*RELATED_$!<Mother>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*RELATED_$!<Mother>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Mother>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([VcardDictionary objectForKey: @"*RELATED_$!<Father>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*RELATED_$!<Father>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Father>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([VcardDictionary objectForKey: @"*RELATED_$!<Parent>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*RELATED_$!<Parent>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Parent>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([VcardDictionary objectForKey: @"*RELATED_$!<Sister>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*RELATED_$!<Sister>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Sister>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([VcardDictionary objectForKey: @"*RELATED_$!<Brother>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*RELATED_$!<Brother>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Brother>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([VcardDictionary objectForKey: @"*RELATED_$!<Child>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*RELATED_$!<Child>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Child>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([VcardDictionary objectForKey: @"*RELATED_$!<Friend>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*RELATED_$!<Friend>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Friend>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([VcardDictionary objectForKey: @"*RELATED_$!<Partner>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*RELATED_$!<Partner>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Partner>!$_\n", itemRunningCount]]; 
		itemRunningCount++;
	}
	if([VcardDictionary objectForKey: @"*RELATED_$!<Manager>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*RELATED_$!<Manager>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Manager>!$_\n", itemRunningCount]]; 
		itemRunningCount++;	
	}
	if([VcardDictionary objectForKey: @"*RELATED_$!<Assistant>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*RELATED_$!<Assistant>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Assistant>!$_\n", itemRunningCount]]; 
		itemRunningCount++;	
		
	}
	if([VcardDictionary objectForKey: @"*RELATED_$!<Spouse>!$_"] != nil)
	{
		formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-ABRELATEDNAMES;type=pref:%@\n", itemRunningCount, [VcardDictionary objectForKey: @"*RELATED_$!<Spouse>!$_"]]];
		formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:_$!<Spouse>!$_\n", itemRunningCount]]; 
		itemRunningCount++;	
		
	}
		
	for(int x = 0; x < [[VcardDictionary allKeys] count]; x++)
	{		
		if([[[VcardDictionary allKeys] objectAtIndex: x] hasPrefix:@"*IM"])
		{
			formattedVcard = [formattedVcard stringByAppendingString:  [NSString stringWithFormat:@"item%i.X-%@;type=pref:%@\n", itemRunningCount, [[VcardDictionary objectForKey:[[VcardDictionary allKeys] objectAtIndex: x]] objectForKey: @"service"], [[VcardDictionary objectForKey:[[VcardDictionary allKeys] objectAtIndex: x]] objectForKey: @"username"]]];
			formattedVcard = [formattedVcard stringByAppendingString: [NSString stringWithFormat:@"item%i.X-ABLabel:%@\n", itemRunningCount, [[[VcardDictionary allKeys] objectAtIndex: x] stringByReplacingOccurrencesOfString: @"*IM" withString: @""]]]; 
			itemRunningCount++;
		}
	}

	
	//end tag for vCard
	formattedVcard = [formattedVcard stringByAppendingString:@"END:VCARD"];
//	[formattedVcard writeToFile:@"test.vcf" atomically:NO ];
}

-(void)recievedVCard: (NSDictionary *)vCardDictionary
{
	[[Beacon shared] startSubBeaconWithName:@"cardrecieved" timeSession:NO];

	BOOL specialData = FALSE;
	userBusy = TRUE;
	
	NSError *error = nil;
	
	NSDictionary *incomingData = vCardDictionary;
	NSDictionary *VcardDictionary = [incomingData objectForKey: @"data"]; 
	
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
		
		//EMAIL handlers
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
		unknownPersonViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModals)] autorelease];

		
        [self presentModalViewController: navController animated:YES];
        [navController release];
		
		[unknownPersonViewController release];
		
		if(specialData)
		{
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
																message:NSLocalizedString(@"This card contains additional details that the device will not display. To view the entire card sync it back to your computer.", @"Extra card details alert message") 
															   delegate:nil 
													  cancelButtonTitle:nil 
													  otherButtonTitles:NSLocalizedString(@"Dismiss", @"Dismiss button title"),nil];
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

- (void)sendOtherVcard:(id)sender
{
	[[Beacon shared] startSubBeaconWithName:@"othersent" timeSession:NO];

	userBusy = TRUE; //user is  busy here
	
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
	browserViewController.navigationItem.prompt = @"Select a Recipient";
    browserViewController.delegate = self;
    browserViewController.defaultAvatar = [UIImage imageNamed:@"defaultavatar.png"];
    
    if ([sender isKindOfClass:[UINavigationController class]])
    {
        [(UINavigationController *)sender pushViewController:browserViewController animated:YES];
    }
    else if ([sender isKindOfClass:[UIBarButtonItem class]])
    {
        UINavigationController *topViewController = (UINavigationController *)[self.navigationController visibleViewController];
        [topViewController.navigationController pushViewController:browserViewController animated:YES];
    }
    
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
	if(!userBusy && self.isFlipped == NO)
	{	
        NSLog(@"Checking queue for messages");
		//if we have a message in queue handle it
		if([self.messageArray count] > 0)
		{
			MessageIsFromQueue = TRUE;
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
			bounce = TRUE;
			[self sendMyVcard:YES];
			[self recievedVCard: lastMessage];
		}
		
		//preview
		else if(buttonIndex == 1)
		{
			bounce = FALSE;
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

-(void)playReceived
{		
	if(!MessageIsFromQueue)
	{		
		if([[NSDate date] timeIntervalSinceDate: self.lastSoundPlayed] > 0.5)
		{			
			[receive play];
			
			
			if (![[[UIDevice currentDevice] model] isEqualToString: @"iPhone"])
				AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
			
			self.lastSoundPlayed = [NSDate date];
		}
	}
	
	MessageIsFromQueue = FALSE;
}

-(void)playSend
{
	[send play];	
}

#pragma mark -
#pragma mark People Picker Functions


- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker 
{
	userBusy = FALSE;

	
	[self dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	userBusy = FALSE;
	
	

	
	if(primaryCardSelecting)
	{        
        [self dismissModalViewControllerAnimated:YES];
        
		ownerRecord = ABRecordGetRecordID(person);
		[self ownerFound];
	}
	
	
	//sending other users vcard
	else
	{
        otherRecord = ABRecordGetRecordID(person);
        
		//user wants to be able to preview cards
		if([[NSUserDefaults standardUserDefaults] boolForKey: @"allowPreview"])
		{
			ABUnknownPersonViewController *unknownPersonViewController = [[ABUnknownPersonViewController alloc] init];
            unknownPersonViewController.unknownPersonViewDelegate = self;
            unknownPersonViewController.addressBook = ABAddressBookCreate();
            unknownPersonViewController.displayedPerson = person;
            unknownPersonViewController.allowsActions = NO;
            unknownPersonViewController.allowsAddingToAddressBook = NO;
            unknownPersonViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", @"Send button title")
                                                                                                              style:UIBarButtonItemStyleDone 
                                                                                                             target:self 
                                                                                                             action:@selector(sendOtherVcard:)] autorelease];
            
            [peoplePicker pushViewController:unknownPersonViewController animated:YES];
            
            [unknownPersonViewController release];
		}
		
		//user does not want to preview cards
		else
		{
            [self dismissModalViewControllerAnimated:YES];
            
			
			[self sendOtherVcard:peoplePicker];
		}
	}
    
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	//we should never get here anyways
	userBusy = FALSE;

	
    return NO;
}
#pragma mark -
#pragma mark image picker 


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
	[[Beacon shared] startSubBeaconWithName:@"picturesent" timeSession:NO];

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
	userBusy = FALSE;
	[self dismissModalViewControllerAnimated:YES];
	[self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];

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
    
    [self hideShareButton];
}

- (void)connectionSucceeded:(RPSNetwork *)sender infoDictionary:(NSDictionary *)infoDictionary
{
	[[Beacon shared] startSubBeaconWithName:@"connectionsucceed" timeSession:NO];
    
    // Kill the timer if it's out there
    NSLog(@"TIMER: Killing overlay timer");
    [self.overlayTimer invalidate];
    self.overlayTimer = nil;
    
    if (self.isShowingOverlayView)
    {
        [self hideOverlayView];
    }
    
    // Disable or enable the "Share" button based on a server flag.
    NSNumber *smsFlag = [infoDictionary objectForKey:@"enable_sms"];
    if (smsFlag && [smsFlag boolValue])
    {
        [self showShareButton];
    }
    else
    {
        [self hideShareButton];
    }
}

- (void)messageReceived:(RPSNetwork *)sender fromPeer:(RPSNetworkPeer *)peer message:(id)message
{	
	//not a ping lets handle it
    if(![message isEqual:@"PING"])
	{
		NSDictionary *incomingData = message;
		
		if(!userBusy)
		{
			[self playReceived];
			
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
								
				UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ has sent you a card", @"Card received action sheet format title"), peer.handle]
																   delegate:self
														  cancelButtonTitle:NSLocalizedString(@"Discard", @"Discard button title")
													 destructiveButtonTitle:nil
														  otherButtonTitles:NSLocalizedString(@"Preview and Exchange", @"Preview and exchange button title"), NSLocalizedString(@"Preview", @"Preview button title") ,  nil];

				alert.tag = 2;
				[alert showInView:self.view];
				[alert release];
			}
			
			//vcard was returned
			else if([[incomingData objectForKey: @"type"] isEqualToString:@"vcard_bounced"])
			{
								
				UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ has sent you a card in exchange for your card", @"Card exchange action sheet format title"), peer.handle]
																   delegate:self
														  cancelButtonTitle:NSLocalizedString(@"Discard", @"Discard button title")
													 destructiveButtonTitle:nil
														  otherButtonTitles:NSLocalizedString(@"Preview", @"Preview button title") ,  nil];
				
				alert.tag = 3;
				[alert showInView:self.view];
				[alert release];
			}
			
			else if([[incomingData objectForKey: @"type"] isEqualToString:@"img"])
			{
				
				UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ has sent you a picture", @"Picture received action sheet format title"), peer.handle]
																   delegate:self
														  cancelButtonTitle:NSLocalizedString(@"Discard", @"Discard button title")
													 destructiveButtonTitle:nil
														  otherButtonTitles:NSLocalizedString(@"Preview", @"Preview button title"), NSLocalizedString(@"Save to Photos", @"Save to photos button title") ,  nil];
				
				alert.tag = 4;
				[alert showInView:self.view];
				[alert release];
			}
		}
		
		else
		{
			if([[NSDate date] timeIntervalSinceDate: self.lastSoundPlayed] > 0.5)
			{
				[receive play];
				if (![[[UIDevice currentDevice] model] isEqualToString: @"iPhone"])
					AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
				
				self.lastSoundPlayed = [NSDate date];
			}
			
			[self.messageArray addObject:[NSDictionary dictionaryWithObjectsAndKeys: peer, @"peer", message, @"message", nil]];
		}
	}
}

- (void)connectionWillReactivate:(RPSNetwork *)sender
{
    NSLog(@"Reconnecting to the server due to wake...");
    [self hideShareButton];
    [self showOverlayView:NSLocalizedString(@"Connecting to the server…", @"Connecting to the server overlay view message") reconnect:YES];
    [[Beacon shared] startSubBeaconWithName:@"reconnecting" timeSession:NO];
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
                                                        message:NSLocalizedString(@"Unable to the send message. The message was too large.", @"Message too large alert message") 
                                                       delegate:nil 
                                              cancelButtonTitle:nil 
                                              otherButtonTitles:NSLocalizedString(@"Dismiss", @"Dismiss button title"), nil];
        [alert show];
        [alert release];
        
        [self hideMessageSendOverlay];
    }
    
    [sender.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)messageSuccess:(RPSNetwork *)sender contextHandle:(NSUInteger)context
{    
	[self hideMessageSendOverlay];
	[self playSend];
}

- (void)messageFailed:(RPSNetwork *)sender contextHandle:(NSUInteger)context
{
	[[Beacon shared] startSubBeaconWithName:@"messagefailed" timeSession:NO];

	
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                        message:NSLocalizedString(@"Error sending message to the remote device.", @"Remote message error")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss button title")
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    
    [self hideMessageSendOverlay];
}


#pragma mark -
#pragma mark ABUnknownPersonViewControllerDelegate methods 

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonViewController didResolveToPerson:(ABRecordRef)person 
{
	userBusy = FALSE;
	[self.navigationController dismissModalViewControllerAnimated: NO];	
	[self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
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
    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:self.messageArray];
    NSLog(@"messageArray: %@", messageArray);
    NSLog(@"writing messageData: %@", messageData);
	[[NSUserDefaults standardUserDefaults] setObject:messageData forKey:@"storedMessages"];
    
    // Write the app version into the defaults
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"defaultsVersion"];
}

#pragma mark -
#pragma mark RPSNetwork notification methods

- (void)networkLocationUpdated:(NSNotification *)aNotification
{
    CLLocation *location = [[aNotification userInfo] objectForKey:@"location"];
	
	if(location.coordinate.longitude+0.0 != 0 && location.coordinate.latitude+0.0 != 0)
	{
		NSLog(@"updating pinch media's stuff with location: %@", location);
		[[Beacon shared] setBeaconLocation:location];
			
	}
	
	else
	{
		NSLog(@"Did not update pinch media location because it was : %@", location);
	}
}

#pragma mark -
#pragma mark Message send UI

- (void)showMessageSendOverlay
{
	userBusy = TRUE;
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
	
	if(!bounce)
	{
		userBusy = FALSE;
		bounce = FALSE;
	}
	
	[self performSelector:@selector(checkQueueForMessages) withObject:nil afterDelay:1.0];
}

#pragma mark -
#pragma mark SMS Modal delegate methods

- (void)smsModalViewWasCancelled:(HSKSMSModalViewController *)smsModalView
{
    userBusy = NO;
    
    [self dismissModalViewControllerAnimated:YES];
}
    
- (void)smsModalView:(HSKSMSModalViewController *)smsModalView enteredPhoneNumber:(NSString *)strippedPhoneNumber
{
    NSLog(@"TODO: send phone number to %@", strippedPhoneNumber);
    
    if (!strippedPhoneNumber)
    {
        NSLog(@"got invalid phone #");
        return;
    }
        
    NSDictionary *smsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"1%@",strippedPhoneNumber],@"phonenumber",
                                   [[RPSNetwork sharedNetwork] networkHash], @"hash", nil];
    
    NSLog(@"smsDictionary: %@", smsDictionary);
    
    NSError *error = nil;
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%d/sms_invite", [[RPSNetwork sharedNetwork] serverHostname], [[RPSNetwork sharedNetwork] serverPort]];
    NSData *result = [NSURLConnection postToURL:[NSURL URLWithString:urlString]
                     variables:smsDictionary 
                         error:&error 
                       timeout:20.0];
    
    NSString *resultString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    NSLog(@"result of SMS Post: %@", resultString);
    
    if ([resultString isEqualToString:@"ok\r\n"])
    {
        [[Beacon shared] startSubBeaconWithName:@"SMSAppStoreLinkSendSuccess" timeSession:NO];
        
        userBusy = NO;
        
        [self dismissModalViewControllerAnimated:YES];
    }
    else
    {
        [[Beacon shared] startSubBeaconWithName:@"SMSAppStoreLinkSendFailed" timeSession:NO];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:NSLocalizedString(@"Unable to send SMS message, please try again later.", @"SMS send failed alert message")
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"Dismiss", @"Dismiss button title"),nil];
        [alert show];
        [alert release];
    }
}

@end
