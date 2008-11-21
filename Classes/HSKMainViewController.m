//
//  HSKViewController.m
//  Handshake
//
//  Created by Kyle on 9/24/08.
//  Copyright Dragon Forged Software 2008. All rights reserved.
//

#import "HSKMainViewController.h"
#import "NSString+SKPPhoneAdditions.h"
#import "UIImage+HSKExtensions.h"
#import "HSKUnknownPersonViewController.h"
#import "HSKFlipsideController.h"
#import "HSKPicturePreviewViewController.h"
#import "HSKCustomAdController.h"
#import "Beacon.h"
#import "NSString+SKPURLAdditions.h"
#import "NSURLConnection+SKPAdditions.h"
#import "HSKEmailPrefsViewController.h"
#import "HSKBeacons.h"
#import "HSKMessageDefines.h"
#import "HSKABMethods.h"
#import "HSKFileBrowser.h"
#import "HSKBypassServer.h"
#import "HSKNetworkIntelligence.h"
#import "HSKMessage.h"


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

@property(nonatomic, retain) UIButton *frontButton;

@property(nonatomic, retain) NSTimer *overlayTimer;
@property(nonatomic, assign) BOOL isFlipped;
@property(nonatomic, assign) BOOL isShowingOverlayView;
@property(nonatomic, assign) BOOL isUIBusy;
@property(nonatomic, retain) NSDate *lastSoundPlayed;

@property(nonatomic, retain) HSKMessage *messageToSend;
@property(nonatomic, retain) HSKMessage *receivedMessage;

- (void)sendOtherVcard:(id)sender;
-(void)recievedPict:(id)picStringOrData;

- (void)playReceived;
- (void)playSend;

- (void)flipBack;

- (void)showOverlayView:(NSString *)prompt reconnect:(BOOL)isReconnect;
- (void)hideOverlayView;
- (void)handleConnectFail;
- (void)doShowOverlayView:(NSTimer *)aTimer;
- (void)showMessageSendOverlay;
- (void)hideMessageSendOverlay;
- (void)showShareButton;
- (void)hideShareButton;
- (void)presentEmailModal;

- (void)receivedVcardMessage:(HSKMessage *)message fromPeer:(RPSNetworkPeer *)peer queueLength:(NSUInteger)queueLength;
- (void)receivedVcardBounceMessage:(HSKMessage *)message fromPeer:(RPSNetworkPeer *)peer queueLength:(NSUInteger)queueLength;
- (void)receivedImageMessage:(HSKMessage *)message fromPeer:(RPSNetworkPeer *)peer queueLength:(NSUInteger)queueLength;

@end

#pragma mark -

@implementation HSKMainViewController

@synthesize frontButton, overlayTimer, isFlipped, messageToSend, receivedMessage, \
    customAdController, lastSoundPlayed, isShowingOverlayView, isUIBusy;


#pragma mark FlipView Functions 


-(IBAction)flipView
{
    self.isFlipped = YES;
	self.isUIBusy = YES;
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
	self.isUIBusy = FALSE;
	
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
}

#pragma mark -
#pragma mark Event handlers


- (IBAction)retryConnection:(id)sender
{
    overlayRetryButton.hidden = YES;
    
    if ([[HSKMessageBus sharedInstance] start])
    {
        [self showOverlayView:NSLocalizedString(@"Connecting to the server…", @"Server connection view title") reconnect:NO];
    }
    else
    {
        [self handleConnectFail];
    }
}

- (IBAction)sendSMS:(id)sender
{
    self.isUIBusy = TRUE;
    
    HSKSMSModalViewController *smsController = [[HSKSMSModalViewController alloc] init];
    smsController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:smsController];
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkLocationUpdated:) name:RSPNetworkLocationChanged object:nil];
		
		send = [[HSKSoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sent" ofType:@"caf"]];
		receive = [[HSKSoundEffect alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"receive" ofType:@"caf"]];
		self.lastSoundPlayed = [NSDate date];
		
		//respect the silent toggle!
		AudioSessionInitialize(nil, nil, nil, nil);
		UInt32	sessionCategory = kAudioSessionCategory_AmbientSound;
		AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
        
        
        self.isUIBusy = YES;
    }	
	return self;
}

- (void)dealloc 
{
	self.frontButton = nil;
    [self.overlayTimer invalidate];
    self.overlayTimer = nil;
    self.customAdController = nil;
	self.lastSoundPlayed = nil;
    self.receivedMessage = nil;
    self.messageToSend = nil;
	

    
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
	self.isUIBusy = FALSE;
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
    [[HSKMessageBus sharedInstance] setDelegate:self];
    
	// Verify that the owner information is properly stored (do this after the runloop has started)
    // (this is guarded with a timer to avoid timeout on launch)
    [self performSelector:@selector(verifyOwnerCard) withObject:nil afterDelay:0.25];
	
	self.view.backgroundColor =[UIColor blackColor];
    
	
    self.view.autoresizesSubviews = YES;
    
    self.frontButton = [[[UIButton alloc] initWithFrame:CGRectMake(0,0,50,29)] autorelease];
    [self.frontButton setBackgroundImage:[UIImage imageNamed:@"Wrench.png"] forState:UIControlStateNormal];
    [self.frontButton addTarget:self action:@selector(flipView) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"Back nav bar button") style:UIBarButtonItemStyleBordered target:self action:@selector(popToSelf:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:self.frontButton] autorelease];
    
#ifdef HS_PREMIUM
    
    [customAdController.verticalFlipImageView removeFromSuperview];
    self.customAdController = nil;
    
#else /* !HS_PREMIUM */
  
    [customAdController startAdServing];
    
#endif
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    NSLog(@"TIMER: Killing overlay timer");
    [self.overlayTimer invalidate];
    self.overlayTimer = nil;
    
	self.isUIBusy = YES;
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
	if(isUIBusy && self.isFlipped == FALSE)
		[self dismissModalViewControllerAnimated:YES];	
	
	self.isUIBusy = TRUE; //user is considered busy when overlay view is showing.
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
        self.isUIBusy = FALSE; //this should be a safe call here
    }    
}

- (void)showShareButton
{
    // Only show this feature for the US and Canada
    UIBarButtonItem *tmpItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Share", @"Share link via SMS button") style:UIBarButtonItemStyleBordered target:self action:@selector(sendSMS:)] autorelease];
    [self.navigationItem setLeftBarButtonItem:tmpItem animated:YES];
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


-(void)returnOwnerEmail
{
	//grab the saved value for our owner card
	ownerRecord = [[NSUserDefaults standardUserDefaults] integerForKey:@"ownerRecordRef"];
	
	//dont do jack unless we have an owner card to do it on
	if(ownerRecord)
	{
		ABRecordRef ownerCard =  ABAddressBookGetPersonWithRecordID(ABAddressBookCreate(), ownerRecord);
		
		for (int x = 0; (ABMultiValueGetCount(ABRecordCopyValueAndAutorelease(ownerCard , kABPersonEmailProperty)) > x); x++)
		{
			NSString *emailaddress = (NSString *)ABMultiValueCopyValueAtIndexAndAutorelease(ABRecordCopyValueAndAutorelease(ownerCard ,kABPersonEmailProperty) , x);
			NSLog(@"Found Owner Email Address Of: %@", emailaddress);		
			break; //just taking the first email address on this cycle
		}
	}
}

#pragma mark -
#pragma mark Owner Functions
-(void)verifyOwnerCard 
{ 
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *myPhoneNumber = [[[defaults dictionaryRepresentation] objectForKey: @"SBFormattedPhoneNumber"] numericOnly];
    
	NSString *phoneNumber = nil;
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
        
        int checkedAddressCount = 0;
        
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
                
                checkedAddressCount++;
                
                if(foundOwner)
                    break;
            }
            [firstName release];
            [lastName release];

            if(foundOwner)
                break;
        }
        
        [addresses release];
        
        NSLog(@"Ended address book iteration (%d iterations), took %d seconds.", checkedAddressCount, time(NULL) - startTime);
		
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
			[self presentModalViewController:picker animated:YES];
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
		UIImage *roundedAvatarImage = [[avatar thumbnail:CGSizeMake(64.0, 64.0)] roundCorners:CGSizeMake(7.0, 7.0)];
		[[NSUserDefaults standardUserDefaults] setObject: UIImagePNGRepresentation(roundedAvatarImage) forKey: @"avatarData"];
		[[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: @"avatarDate"];
	}

	//the card has been modified since we last loaded avatar data
	else if([(NSDate *) ABRecordCopyValueAndAutorelease(ownerCard, kABPersonModificationDateProperty) compare: [[NSUserDefaults standardUserDefaults] objectForKey: @"avatarDate"]] == NSOrderedDescending)
	{
		avatar = ABPersonHasImageData (ownerCard) ? [UIImage imageWithData: (NSData *)ABPersonCopyImageData(ownerCard)] : [UIImage imageNamed: @"defaultavatar.png"];
		UIImage *roundedAvatarImage = [[avatar thumbnail:CGSizeMake(64.0, 64.0)] roundCorners:CGSizeMake(7.0, 7.0)];
		[[NSUserDefaults standardUserDefaults] setObject: UIImagePNGRepresentation(roundedAvatarImage) forKey: @"avatarData"];
		[[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: @"avatarDate"];
	}
    
    if (![[HSKMessageBus sharedInstance] start])
    {
        [self handleConnectFail];
    }
}

#pragma mark -
#pragma mark Send & Receive 

- (void)sendVcard;
{
	[[Beacon shared] startSubBeaconWithName:kHSKBeaconBeginSendVcardEvent timeSession:NO];

	self.isUIBusy = TRUE;
	
	recordToSend = ownerRecord;
	
//    self.cookieToSend = [HSKMessage generateCookie];
//	[self.objectsToSend setObject:[[HSKABMethods sharedInstance] sendMyVcard:bounce forRecord:recordToSend] forKey:self.cookieToSend];
    
    
    HSKMessage *message = [HSKMessage message];
    message.cookie = [HSKMessage generateCookie];
    message.version = kHSKProtocolVersion;
	message.type = bounce ? @"vcard_bounced" : @"vcard";
    message.data = [[HSKABMethods sharedInstance] sendMyVcard:bounce forRecord:recordToSend];
    self.messageToSend = message;
	
    if (!bounce)
    {
		[[Beacon shared] startSubBeaconWithName:kHSKBeaconBrowsingForPeerEvent timeSession:NO];
		RPSBrowserViewController *browserViewController = [[RPSBrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:browserViewController];
		browserViewController.delegate = self;
		browserViewController.defaultAvatar = [UIImage imageNamed:@"defaultavatar.png"];
		[self.navigationController presentModalViewController:navController animated:YES];
		[browserViewController release];	
		[navController release];
		
	}
	
    else
    {
		[[Beacon shared] startSubBeaconWithName:kHSKBeaconBouncingCardEvent timeSession:NO];
        // RPSNetwork *network = [RPSNetwork sharedNetwork];
        
        // TODO: send the ready to send message
        // [network sendMessage: self.objectToSend toPeer: receivedMessage.fromPeer compress:YES];
    }
}

-(void) recievedVcard;
{
	BOOL specialData = FALSE; 
	
	ABRecordRef newPerson = [[HSKABMethods sharedInstance] recievedVCard:receivedMessage.data fromPeer:receivedMessage.fromPeer.handle];
	
	HSKUnknownPersonViewController *unknownPersonViewController = [[HSKUnknownPersonViewController alloc] init];
	unknownPersonViewController.unknownPersonViewDelegate = self;
	unknownPersonViewController.addressBook = ABAddressBookCreate();
	unknownPersonViewController.displayedPerson = newPerson;
	unknownPersonViewController.allowsActions = NO;
	unknownPersonViewController.allowsAddingToAddressBook = YES;
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:unknownPersonViewController];
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

- (void)sendOtherVcard:(id)sender
{
	[[Beacon shared] startSubBeaconWithName:kHSKBeaconBeginSendOtherVcardEvent timeSession:NO];

	self.isUIBusy = TRUE; //user is  busy here
	
	recordToSend = otherRecord;
	
    self.messageToSend = [HSKMessage message];
    messageToSend.cookie = [HSKMessage generateCookie];
    messageToSend.version = kHSKProtocolVersion;
    messageToSend.type = bounce ? @"vcard_bounced" : @"vcard";
    messageToSend.data = [[HSKABMethods sharedInstance] sendMyVcard:bounce forRecord:recordToSend];

	[[Beacon shared] startSubBeaconWithName:kHSKBeaconBrowsingForPeerEvent timeSession:YES];

	RPSBrowserViewController *browserViewController = [[RPSBrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
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
}

-(void)recievedPict:(id)picStringOrData
{	
	[[Beacon shared] startSubBeaconWithName:kHSKBeaconReceivedPictureEvent timeSession:NO];

	self.isUIBusy = TRUE;
		
	NSData *data = [picStringOrData isKindOfClass:[NSString class]] ? [NSData decodeBase64ForString:picStringOrData] : picStringOrData;
	
    UIImage *receivedImage = [UIImage imageWithData: data];
    
    HSKPicturePreviewViewController *picPreviewController = [[HSKPicturePreviewViewController alloc] initWithNibName:@"PicturePreviewViewController" bundle:nil];
    [picPreviewController view];
    picPreviewController.pictureImageView.image = receivedImage;
    picPreviewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:picPreviewController];
    [self presentModalViewController:navController animated:YES];
    [navController release];
    [picPreviewController release];
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
            self.isUIBusy = TRUE;
            
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
	else if (actionSheet.tag == 2)
    {
		//preview and bounce
		if(buttonIndex == 0)
		{
			bounce = TRUE;
			[self sendVcard];
			self.isUIBusy = TRUE;
			[self recievedVcard];
		}
		
		//preview
		else if(buttonIndex == 1)
		{
			bounce = FALSE;
			self.isUIBusy = FALSE;
			[self recievedVcard];
		}
		
		//discard
		else if(buttonIndex == 2)
		{
			//do nothing
			self.isUIBusy = FALSE;
		}		
	}
	
	//bounce card recieved
	else if (actionSheet.tag == 3)
    {
		if(buttonIndex == 0)
		{
			self.isUIBusy = TRUE;
			[self recievedVcard];

		}
		
		else if(buttonIndex == 1)
		{
			//do nothing
			self.isUIBusy = FALSE;
		}

	}
	
	
	//picture received
	else if (actionSheet.tag == 4)
    {
		if(buttonIndex == 0)
		{
			//preview
			[self recievedPict:receivedMessage.data];
			
		}
		
		else if(buttonIndex == 1)
		{
			//save without preview
			self.isUIBusy = TRUE;
			            
			NSData *data = [NSData decodeBase64ForString:receivedMessage.data]; 
						
			UIImageWriteToSavedPhotosAlbum([UIImage imageWithData: data], nil, nil, nil);
		}
		
		else if(buttonIndex == 2)
		{
			//discard Do Nothing
			self.isUIBusy = FALSE;
		}
		
	}
	
	//card received > 10 queue
	else if (actionSheet.tag == 5)
    {
		if(buttonIndex == 0)
		{
			NSLog(@"Clearing all messages");
			//clear all messages
			[[HSKMessageBus sharedInstance] removeAllMessages];
			self.isUIBusy = FALSE;
		}
		
		//preview and bounce
		else if(buttonIndex == 1)
		{
			bounce = TRUE;
			[self sendVcard];
			self.isUIBusy = TRUE;
			[self recievedVcard];
	
		}
		
		//preview
		else if(buttonIndex == 2)
		{
			bounce = FALSE;
			self.isUIBusy = TRUE;
			[self recievedVcard];

		}
		
		else if(buttonIndex == 4)
		{
			//discard
			self.isUIBusy = FALSE;
		}
		
	}
	
	//card bounce > 10
	else if (actionSheet.tag == 6)
    {
		if(buttonIndex == 0)
		{
			NSLog(@"Clearing all messages");
			//clear all messages
			//[self.messageArray removeAllObjects];
            [[HSKMessageBus sharedInstance] removeAllMessages];
			self.isUIBusy = FALSE;
		}
		
		//preview
		else if(buttonIndex == 1)
		{
			self.isUIBusy = TRUE;
			[self recievedVcard];

		}
		
		//discard
		else if(buttonIndex == 2)
		{
			self.isUIBusy = FALSE;
		}		
	}
	
	
	//picture received > 10
	else if (actionSheet.tag == 7)
    {
		if(buttonIndex == 0)
		{
			NSLog(@"Clearing all messages");
			//clear all messages
			[[HSKMessageBus sharedInstance] removeAllMessages];
			self.isUIBusy = FALSE;
		}
		
		else if(buttonIndex == 1)
		{
			//preview
			[self recievedPict: receivedMessage.data];
		}
		
		else if(buttonIndex == 2)
		{
			//save without preview
			self.isUIBusy = TRUE;
			
			NSData *data = [NSData decodeBase64ForString:receivedMessage.data]; 
			
			UIImageWriteToSavedPhotosAlbum([UIImage imageWithData: data], nil, nil, nil);
			
		}
		
		else if(buttonIndex == 4)
		{
			//Discard
			self.isUIBusy = FALSE;
		}
		
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{	
	//yes add to our photo album
    if (alertView.tag == 0)
    {
        if(buttonIndex == 1)
        {
            [self recievedPict: receivedMessage.data];
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
    if([[NSDate date] timeIntervalSinceDate: self.lastSoundPlayed] > 0.5)
    {			
        [receive play];
        
        
        if (![[[UIDevice currentDevice] model] isEqualToString: @"iPhone"])
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        
        self.lastSoundPlayed = [NSDate date];
    }
}

-(void)playSend
{
	[send play];	
}

#pragma mark -
#pragma mark People Picker Functions


- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker 
{
	self.isUIBusy = FALSE;

	
	[self dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	self.isUIBusy = FALSE;
	
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
			[self sendOtherVcard:peoplePicker];
		}
	}
    
    return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	//we should never get here anyways
	self.isUIBusy = FALSE;

	
    return NO;
}
#pragma mark -
#pragma mark image picker 


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
	[[Beacon shared] startSubBeaconWithName:kHSKBeaconBeginSendPictureEvent timeSession:NO];

    NSData *data = UIImageJPEGRepresentation(image, 0.5);
    
    self.messageToSend = [HSKMessage message];
    messageToSend.cookie = [HSKMessage generateCookie];
    messageToSend.version = kHSKProtocolVersion;
    messageToSend.type = kHSKMessageTypeImage;
    messageToSend.data = [data encodeBase64ForData];
	
	[[Beacon shared] startSubBeaconWithName:kHSKBeaconBrowsingForPeerEvent timeSession:YES];
	
	RPSBrowserViewController *browserViewController = [[RPSBrowserViewController alloc] initWithNibName:@"BrowserViewController" bundle:nil];
    browserViewController.delegate = self;
    browserViewController.defaultAvatar = [UIImage imageNamed:@"defaultavatar.png"];
    [picker pushViewController:browserViewController animated:YES];
    [browserViewController release];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	self.isUIBusy = FALSE;
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

	return 4;
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
		
		else if ([indexPath row] == 3)
		{
			cell.text = @"Send a File";
			[cell setImage:  [UIImage imageNamed: @"filesIcon.png"]];
		}
	}
	
		
	//adds the disclose indictator. 
	// cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	// Configure the cell
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.isUIBusy = YES;
	//do that HIG glow thing that apple likes so much
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
	
	//send my vCard
	if ([indexPath row] == 0)
	{
		[self sendVcard];
	}
	
	//send someone elses card
	if ([indexPath row] == 1)
	{
		self.isUIBusy = TRUE; //dont want to pop queue when user is looking for someone
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
	
	if([indexPath row] == 3)
	{
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [[paths objectAtIndex:0] stringByAppendingString: @"/Handshake"];
		
		if(![[NSFileManager defaultManager] fileExistsAtPath: documentsDirectory])
		{
			//if we dont have a directory for handshake yet create one.
			[[NSFileManager defaultManager] createDirectoryAtPath: documentsDirectory attributes:nil];
		}
		
		
		HSKFileBrowser *fileBrowserViewController = [[HSKFileBrowser alloc] initWithDirectory: documentsDirectory ];		
		[self.navigationController pushViewController:fileBrowserViewController animated: YES];
		[fileBrowserViewController release];
	}
}


#pragma mark -
#pragma mark Message Processing methods

- (void)receivedVcardMessage:(HSKMessage *)message fromPeer:(RPSNetworkPeer *)peer queueLength:(NSUInteger)queueLength
{
    //we do not have a huge queue
    if(queueLength < 10)
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
    
    //more then 10 messages in queue
    else
    {
        UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ has sent you a card", @"Card received action sheet format title"), peer.handle]
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Discard", @"Discard button title")
                                             destructiveButtonTitle:NSLocalizedString(@"Discard All", @"Discard All button title")
                                                  otherButtonTitles:NSLocalizedString(@"Preview and Exchange", @"Preview and exchange button title"), NSLocalizedString(@"Preview", @"Preview button title") ,  nil];
        
        
        alert.tag = 5;
        [alert showInView:self.view];
        [alert release];
    }
}

- (void)receivedVcardBounceMessage:(HSKMessage *)message fromPeer:(RPSNetworkPeer *)peer queueLength:(NSUInteger)queueLength
{
    if(queueLength < 10)
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
    
    else
    {
        UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ has sent you a card in exchange for your card", @"Card exchange action sheet format title"), peer.handle]
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Discard", @"Discard button title")
                                             destructiveButtonTitle:NSLocalizedString(@"Discard All", @"Discard all button title")
                                                  otherButtonTitles:NSLocalizedString(@"Preview", @"Preview button title") ,  nil];
        
        alert.tag = 6;
        [alert showInView:self.view];
        [alert release];
        
        
    }
}

- (void)receivedImageMessage:(HSKMessage *)message fromPeer:(RPSNetworkPeer *)peer queueLength:(NSUInteger)queueLength
{
    if(queueLength < 10)
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
    
    else
    {
        
        UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ has sent you a picture", @"Picture received action sheet format title"), peer.handle]
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Discard", @"Discard button title")
                                             destructiveButtonTitle:NSLocalizedString(@"Discard All", @"Discard all button title")
                                                  otherButtonTitles:NSLocalizedString(@"Preview", @"Preview button title"), NSLocalizedString(@"Save to Photos", @"Save to photos button title") ,  nil];
        
        alert.tag = 7;
        [alert showInView:self.view];
        [alert release];
        
    }
}



#pragma mark -
#pragma mark RPSBrowserViewControllerDelegate methods

- (void)browserViewController:(RPSBrowserViewController *)sender selectedPeer:(RPSNetworkPeer *)peer
{
	[[Beacon shared] endSubBeaconWithName:kHSKBeaconBrowsingForPeerEvent];
	
    RPSNetwork *network = [RPSNetwork sharedNetwork];

	if (peer)
    {
        [self showMessageSendOverlay];
        
        @try
        {            
            [[HSKMessageBus sharedInstance] sendMessage:messageToSend
                                                 toPeer:peer 
                                               compress:YES];
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
    
    
        // if it was cancelled, then we don't need to do this
        [sender.parentViewController dismissModalViewControllerAnimated:YES];
    }
    else
    {
        self.isUIBusy = NO;
    }
}

- (void)browserViewControllerAlternateAction:(RPSBrowserViewController *)sender
{    
    NSString *emailAddress = [[NSUserDefaults standardUserDefaults] objectForKey:HSKMailAddressDefault];
    NSString *hostPort = [[NSUserDefaults standardUserDefaults] objectForKey:HSKMailHostPortDefault];
    
    if ( (emailAddress == nil) || ( hostPort == nil) || ([emailAddress length] == 0) || ([hostPort length] == 0) )
    {
        HSKEmailPrefsViewController *emailPrefs = [[HSKEmailPrefsViewController alloc] initWithNibName:@"HSKPrefsTableViewController" bundle:nil];
        emailPrefs.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(emailSettingsCancel)] autorelease];
        emailPrefs.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(emailSettingsDone)] autorelease];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:emailPrefs];
        [sender presentModalViewController:navController animated:YES];
        [navController release];
        [emailPrefs release];
    }
    else
    {
        [self presentEmailModal];
    }
}

- (void)presentEmailModal
{
    HSKEmailModalViewController *emailController = [[HSKEmailModalViewController alloc] initWithNibName:@"EmailModalView" bundle:nil];
    emailController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:emailController];
    [self.modalViewController presentModalViewController:navController animated:YES];
    [emailController release];
    [navController release];
}

#pragma mark -
#pragma mark ABUnknownPersonViewControllerDelegate methods 

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonViewController didResolveToPerson:(ABRecordRef)person 
{
	self.isUIBusy = FALSE;
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
	self.isUIBusy = TRUE;
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
		self.isUIBusy = FALSE;
	}
	
	bounce = FALSE;
	
}
#pragma mark -
#pragma mark Email Modal delegate methods

- (void)emailModalViewWasCancelled:(HSKEmailModalViewController *)emailModalView
{
    // No userbusy flag change here
    
    [emailModalView.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)emailModalView:(HSKEmailModalViewController *)emailModalView enteredEmail:(NSString *)email
{    
    SKPSMTPMessage *vcardMsg = [[SKPSMTPMessage alloc] init];
    
    NSString *hostAndPort = [[NSUserDefaults standardUserDefaults] objectForKey:HSKMailHostPortDefault];
    NSArray *components = [hostAndPort componentsSeparatedByString:@":"];
    if ([components count] > 1)
    {
        vcardMsg.relayPorts = [NSArray arrayWithObject:[NSNumber numberWithShort:atoi([[components objectAtIndex:1] UTF8String])]];
    }
    
    vcardMsg.relayHost = [components objectAtIndex:0];
    vcardMsg.fromEmail = [[NSUserDefaults standardUserDefaults] objectForKey:HSKMailAddressDefault];
    vcardMsg.toEmail = email;
    
    if (([[NSUserDefaults standardUserDefaults] objectForKey:HSKMailLoginDefault] != nil) && ([[NSUserDefaults standardUserDefaults] objectForKey:HSKMailPasswordDefault] != nil))
    {
        vcardMsg.requiresAuth = YES;
        vcardMsg.login = [[NSUserDefaults standardUserDefaults] objectForKey:HSKMailLoginDefault];
        vcardMsg.pass = [[NSUserDefaults standardUserDefaults] objectForKey:HSKMailPasswordDefault];
    }
    
    vcardMsg.subject = NSLocalizedString(@"A Message from Handshake", @"Email Subject line");
    vcardMsg.wantsSecure = YES;
    vcardMsg.delegate = self;
    
    NSString *plainTextBody = nil;    
    
    NSDictionary *attachmentPart = nil;
    
    //NSDictionary *objectToSend = [self.objectsToSend objectForKey:self.cookieToSend];
    
    if ([messageToSend.type isEqualToString:kHSKMessageTypeVcard])
    {
        [[Beacon shared] startSubBeaconWithName:kHSKBeaconEmailCardEvent timeSession:NO];
        
        NSDictionary *cardData = messageToSend.data;
        NSString *vCardFN = nil;
        
        plainTextBody = [NSString stringWithFormat:NSLocalizedString(@"Here's a card from Handshake!\r\n\r\nFrom,\r\n\r\n%@\r\n\r\nhttp://gethandshake.com/\r\n\r\n---\r\n", @"Email body format string"), [[RPSNetwork sharedNetwork] handle]];
        
        if ([cardData objectForKey:@"FirstName"] && [cardData objectForKey:@"LastName"])
        {
            vCardFN = [NSString stringWithFormat:@"%@ %@", [cardData objectForKey:@"FirstName"], [cardData objectForKey:@"LastName"]];
        }
        else if ([cardData objectForKey:@"OrgName"])
        {
            vCardFN = [NSString stringWithFormat:@"%@", [cardData objectForKey:@"OrgName"], nil];
        }
        else if ([cardData objectForKey:@"LastName"])
        {
            vCardFN = [NSString stringWithFormat:@"%@", [cardData objectForKey:@"LastName"], nil];
        }
        else if ([cardData objectForKey:@"FirstName"])
        {
            vCardFN = [NSString stringWithFormat:@"%@", [cardData objectForKey:@"FirstName"], nil];
        }
        else
        {
            vCardFN = NSLocalizedString(@"vcard", @"Default vcard attachment filename for email");
        }
        
        vCardFN = [[vCardFN stringByReplacingOccurrencesOfString:@"." withString:@""] stringByAppendingString:@".vcf"];
        
        
        NSString *contentType = [NSString stringWithFormat:@"text/directory;\r\n\tx-unix-mode=0644;\r\n\tname=\"%@\"", vCardFN];
        NSString *contentDisposition = [NSString stringWithFormat:@"attachment;\r\n\tfilename=\"%@\"", vCardFN];
        
        NSData *vcfData = [[[HSKABMethods sharedInstance] formatForVcard:cardData] dataUsingEncoding:NSUTF8StringEncoding];
        attachmentPart = [NSDictionary dictionaryWithObjectsAndKeys:contentType,kSKPSMTPPartContentTypeKey,
                          contentDisposition,kSKPSMTPPartContentDispositionKey,
                          [vcfData encodeWrappedBase64ForData],kSKPSMTPPartMessageKey,
                          @"base64",kSKPSMTPPartContentTransferEncodingKey,nil];
    }
    else if ([messageToSend.type isEqualToString:kHSKMessageTypeImage])
    {   
        [[Beacon shared] startSubBeaconWithName:kHSKBeaconEmailCardEvent timeSession:NO];
        
        plainTextBody = [NSString stringWithFormat:NSLocalizedString(@"Here's a picture from Handshake!\r\n\r\nFrom,\r\n\r\n%@\r\n\r\nhttp://gethandshake.com/\r\n\r\n---\r\n", @"Email body format string"), [[RPSNetwork sharedNetwork] handle]];
        
        NSString *imageFN = @"image.jpg";
        
        NSString *contentType = [NSString stringWithFormat:@"image/jpeg;\r\n\tx-unix-mode=0644;\r\n\tname=\"%@\"", imageFN];
        NSString *contentDisposition = [NSString stringWithFormat:@"attachment;\r\n\tfilename=\"%@\"", imageFN];
        
        NSData *imageData = [NSData decodeBase64ForString:messageToSend.data];
        NSString *wrappedBase64 = [imageData encodeWrappedBase64ForData];
        
        attachmentPart = [NSDictionary dictionaryWithObjectsAndKeys:contentType,kSKPSMTPPartContentTypeKey,
                          contentDisposition,kSKPSMTPPartContentDispositionKey,
                          wrappedBase64,kSKPSMTPPartMessageKey,
                          @"base64",kSKPSMTPPartContentTransferEncodingKey,nil];
    }
    else
    {
        NSAssert(NO, @"unknown data type!");
    }
    
    NSDictionary *plainPart = [NSDictionary dictionaryWithObjectsAndKeys:@"text/plain",kSKPSMTPPartContentTypeKey,
                               plainTextBody,kSKPSMTPPartMessageKey,@"7bit",kSKPSMTPPartContentTransferEncodingKey,nil];
    
    vcardMsg.parts = [NSArray arrayWithObjects:plainPart,attachmentPart,nil];
        
    [self dismissModalViewControllerAnimated:YES];
    
    // Show the message send overlay
    [self showMessageSendOverlay];
    
    // Send the message
    [vcardMsg send];
}

#pragma mark -
#pragma mark Email Setup modal event handler methods

- (void)emailSettingsCancel
{
    [self.modalViewController dismissModalViewControllerAnimated:YES];
}

- (void)emailSettingsDone
{
    [self.modalViewController dismissModalViewControllerAnimated:YES];
    
    [self performSelector:@selector(presentEmailModal) withObject:nil afterDelay:0.5];
}

#pragma mark -
#pragma mark SMS Modal delegate methods

- (void)smsModalViewWasCancelled:(HSKSMSModalViewController *)smsModalView
{
    self.isUIBusy = NO;
    
    [self dismissModalViewControllerAnimated:YES];
}
    
- (void)smsModalView:(HSKSMSModalViewController *)smsModalView enteredPhoneNumber:(NSString *)strippedPhoneNumber
{    
    if (!strippedPhoneNumber)
    {
        NSLog(@"got invalid phone #");
        return;
    }
        
    NSDictionary *smsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@",strippedPhoneNumber],@"phonenumber",
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
        [[Beacon shared] startSubBeaconWithName:kHSKBeaconSMSAppStoreLinkSendSuccess timeSession:NO];
        
        self.isUIBusy = NO;
        
        [self dismissModalViewControllerAnimated:YES];
    }
    else
    {
        [[Beacon shared] startSubBeaconWithName:kHSKBeaconSMSAppStoreLinkSendFail timeSession:NO];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:NSLocalizedString(@"Unable to send SMS message, please try again later.", @"SMS send failed alert message")
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"Dismiss", @"Dismiss button title"),nil];
        [alert show];
        [alert release];
    }
}

#pragma mark -
#pragma mark SKPSMTPMessageDelgate methods

- (void)messageSent:(SKPSMTPMessage *)message
{
    [message release];
    
    NSLog(@"delegate - message sent");
    
    [self hideMessageSendOverlay];
    [self playSend];
}

- (void)messageFailed:(SKPSMTPMessage *)message error:(NSError *)error
{
    [message release];
    
    NSLog(@"delegate - error(%d): %@", [error code], [error localizedDescription]);
    
    [self hideMessageSendOverlay];
    
    NSString *msg = nil;
    
    switch ([error code])
    {
        case kSKPSMTPErrorConnectionFailed:
            msg = NSLocalizedString(@"Unable to connect to your mail server, please check your email settings.", @"Email server connection fail alert message");
            break;
        case kSKPSMTPErrorConnectionInterrupted:
            msg = NSLocalizedString(@"An error occurred while your message was being sent.", @"Email server connection interrupted alert message");
            break;
        case kSKPSMTPErrorInvalidMessage:
            msg = NSLocalizedString(@"The server did not accept your message. Please check your email address in settings.", @"Email server rejected message alert message");
            break;
        case kSKPSMTPErrorInvalidUserPass:
            msg = NSLocalizedString(@"The server did not accept your username and password, please check your email settings", @"Email server bad username or password alert message");
            break;
        case kSKPSMTPErrorTLSFail:
            msg = NSLocalizedString(@"An error occurred while negotiating a secure connection with the server.", @"Email server failed to setup security alert message");
            break;
        case kSKPSMTPErrorUnsupportedLogin:
            msg = NSLocalizedString(@"Your server is not supported by Handshake, please check your email settings.", @"Email server not supported alert message");
            break;
        case kSKPSMTPErrorNoRelay:
            msg = NSLocalizedString(@"Your server did not accept the message for relay. Please check your email settings and make sure you have supplied a User Name and a Password.", @"Email server relay rejected alert message");
            break;
        default:
            msg = NSLocalizedString(@"An error occurred while sending your message.", @"Non-specific email error alert message");
            break;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:msg
                                                   delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Dismiss", @"Dismiss alert button title"), nil];
    [alert show];
    [alert release];
}





#pragma mark -
#pragma mark HSKPicturePreviewViewControllerDelegate methods

- (void)picturePreviewierDidClose:(HSKPicturePreviewViewController *)sender
{
    self.isUIBusy = NO;    
}

#pragma mark -
#pragma mark HSKMessageBusDelegate methods

- (void)messageBus:(HSKMessageBus *)sender willSendMessage:(HSKMessage *)message
{
    [self showMessageSendOverlay];
}

- (void)messageBus:(HSKMessageBus *)sender didSendMessage:(HSKMessage *)message
{
    [self hideMessageSendOverlay];
	[self playSend];
}

- (void)messageBus:(HSKMessageBus *)sender didFailMessageSend:(HSKMessage *)message
{
    [[Beacon shared] startSubBeaconWithName:kHSKBeaconMessageFailedEvent timeSession:NO];
    
	
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                        message:NSLocalizedString(@"Error sending message to the remote device.", @"Remote message error")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss button title")
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    
    [self hideMessageSendOverlay];
}

- (void)messageBus:(HSKMessageBus *)sender willReceiveMessage:(HSKMessage *)message
{
}
- (void)messageBus:(HSKMessageBus *)sender didReceiveMessage:(HSKMessage *)message
{
}
- (void)messageBus:(HSKMessageBus *)sender didFailMessageReceive:(HSKMessage *)message
{
}

- (void)messageBusWillConnect:(HSKMessageBus *)sender
{
    // Occlude the UI.
    [self showOverlayView:NSLocalizedString(@"Connecting to the server…", @"Server connection view title") reconnect:NO];
}
- (void)messageBusDidConnect:(HSKMessageBus *)sender
{
    // Kill the timer if it's out there
    NSLog(@"TIMER: Killing overlay timer");
    [self.overlayTimer invalidate];
    self.overlayTimer = nil;
    
    if (self.isShowingOverlayView)
    {
        [self hideOverlayView];
    }
    else
    {
        // Still need to flip the flag
        self.isUIBusy = NO;
    }
    
    // TODO: Disable or enable the "Share" button based on a server flag.
#if 0
    NSNumber *smsFlag = [infoDictionary objectForKey:@"enable_sms"];
    if (smsFlag && [smsFlag boolValue])
    {
        [self showShareButton];
    }
    else
    {
        [self hideShareButton];
    }
#endif
}

- (void)messageBusDidDisconnect:(HSKMessageBus *)sender
{
    [self handleConnectFail];
    
    [self hideShareButton];
}

- (void)messageBusWillReactivate:(HSKMessageBus *)sender
{
    // TODO: hide the share button
    // [self hideShareButton];
    [self showOverlayView:NSLocalizedString(@"Connecting to the server…", @"Connecting to the server overlay view message") reconnect:YES];
    [[Beacon shared] startSubBeaconWithName:kHSKBeaconServerBeginReconnectionEvent timeSession:NO];
}

- (NSData *)messageBusDataForAvatar:(HSKMessageBus *)sender
{
    return [[NSUserDefaults standardUserDefaults] objectForKey: @"avatarData"];	
}

- (NSString *)messageBusHandleForUser:(HSKMessageBus *)sender
{
    NSString *handle = nil;
    
    if([[NSUserDefaults standardUserDefaults] stringForKey: @"ownerNameString"] != nil)
	{
		handle = [[NSUserDefaults standardUserDefaults] stringForKey: @"ownerNameString"] ;
	}
	else
	{
        ABAddressBookRef addressBook = ABAddressBookCreate();
        ABRecordRef ownerCard = ABAddressBookGetPersonWithRecordID(addressBook, ownerRecord);
        
        NSAssert(ownerCard != NULL, @"unable to resolve owner card!");
        
		//nil guards
		if((NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonFirstNameProperty) != nil && (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonLastNameProperty) != nil)
			handle = [NSString stringWithFormat:@"%@ %@", (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonFirstNameProperty),(NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonLastNameProperty)];
		else if((NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonFirstNameProperty) != nil)
			handle = (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonFirstNameProperty);
		else if((NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonLastNameProperty) != nil)
			handle = (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonLastNameProperty);
		else
			handle = (NSString *)ABRecordCopyValueAndAutorelease(ownerCard, kABPersonOrganizationProperty);
        
        // CFRelease(ownerCard);
        CFRelease(addressBook);
	}
    
    return handle;
}

// The delegate should attempt to process this message. 
//
// This method is called when the run loop is idle
//
// If the delegate does not process the message, it will return NO.
// If the delegate processes the message, it will return YES.
- (BOOL)messageBus:(HSKMessageBus *)sender processMessage:(HSKMessage *)message queueLength:(NSUInteger)queueLength
{    
    BOOL processedMessage = YES;
    
    if (isUIBusy)
    {
        processedMessage = NO;
    }
    else
    {
        [self playReceived];
        
        //client sees	
        self.receivedMessage = message;
        
        self.isUIBusy = TRUE;
        //App will not let user proceed if if is about to post a message but if you hit it spot
        //on it will highlight the row and lock it
        [mainTable deselectRowAtIndexPath: [mainTable indexPathForSelectedRow] animated: YES];
        
        if([message.type isEqualToString:kHSKMessageTypeVcard])
        {
            [self receivedVcardMessage:message fromPeer:message.fromPeer queueLength:queueLength];
        }
        //vcard was returned
        else if([message.type isEqualToString:kHSKMessageTypeVcardBounced])
        {
            [self receivedVcardBounceMessage:message fromPeer:message.fromPeer queueLength:queueLength];
        }
        else if([message.type isEqualToString:kHSKMessageTypeImage])
        {
            [self receivedImageMessage:message fromPeer:message.fromPeer queueLength:queueLength];
        }
    }
    
    return processedMessage;
}

#pragma mark -
#pragma mark Accessor methods

- (void)setIsUIBusy:(BOOL)flag
{
    if (isUIBusy != flag)
    {
        isUIBusy = flag;
        NSString *busyStr = flag ? @"YES" : @"NO";
        NSLog(@"isUIBusy: %@", busyStr);
    }
}

@end
