/*
 *  HSKMessageDefines.m
 *  Handshake
 *
 *  Created by Ian Baird on 11/4/08.
 *  Copyright 2008 Skorpiostech, Inc. All rights reserved.
 *
 */

#include "HSKMessageDefines.h"

NSString *kHSKProtocolVersion1_0 = @"1.0";
NSString *kHSKProtocolVersion2_0 = @"2.0";

NSString *kHSKMessageTypeKey = @"type";
NSString *kHSKMessageWrappedTypeKey = @"wrapped_type";
NSString *kHSKMessageCookieKey = @"cookie";
NSString *kHSKMessageDataKey = @"data";
NSString *kHSKMessageVersionKey = @"version";
NSString *kHSKMessageListenAddrsKey = @"listen_addrs";
NSString *kHSKMessageDeclinedKey = @"declined";

NSString *kHSKMessageTypeVcard = @"vcard";
NSString *kHSKMessageTypeVcardBounced = @"vcard_bounced";
NSString *kHSKMessageTypeImage = @"img";
NSString *kHSKMessageTypeFile = @"file";
NSString *kHSKMessageTypeReadyToSend = @"ready_to_send";
NSString *kHSKMessageTypeReadyToReceive = @"ready_to_receive";
