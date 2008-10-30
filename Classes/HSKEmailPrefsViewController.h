//
//  HSKPrefsTableViewController.h
//  Handshake
//
//  Created by Ian Baird on 10/28/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *HSKMailAddressDefault;
extern NSString *HSKMailHostPortDefault;
extern NSString *HSKMailLoginDefault;
extern NSString *HSKMailPasswordDefault;

// Gmail
// incoming: imap.gmail.com
// outgoing: smtp.gmail.com
// ports: 25, 465, 587
// SSL supported
//
// .mac
// IMAP
// Incoming : mail.mac.com
// Outgoing: smtp.mac.com
// ports: 25, 465, 587
// SSL supported
//
// yahoo
// POP
// Incoming: plus.pop.mail.yahoo.com
// Outgoing: plus.smtp.mail.yahoo.com
// SSL supported
// ports: 25, 465, 587
//
// AOL
// IMAP
// Incoming: imap.aol.com
// Outgoing: smtp.aol.com
// SSL supported
// ports: 25, 465, 587
//
// Apple
// Incoming: mail.apple.com
// Outgoing: relay.apple.com
// SSL supported
// ports: 25, 465, 587
//


enum  
{
    kHSKEmailDomainCustom = 0,
    kHSKEmailDomainGmail,
    kHSKEmailDomainDotMac,
    kHSKEmailDomainYahoo,
    kHSKEmailDomainAOL,
    kHSKEmailDomainApple
};
typedef NSUInteger HSKEmailDomain;


@interface HSKEmailPrefsViewController : UITableViewController <UITextFieldDelegate>
{
    
}

@end
