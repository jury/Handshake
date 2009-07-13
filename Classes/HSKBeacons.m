/*
 *  HSKBeacons.m
 *  Handshake
 *
 *  Created by Ian Baird on 11/3/08.
 *
 */
 
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
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#include "HSKBeacons.h"

NSString *kHSKBeaconAdTouchFormat = @"Ad Click: %@";
NSString *kHSKBeaconDFSWLogoTouch = @"Clicked DFSW Logo";
NSString *kHSKBeaconSkorpiostechLogoTouch = @"Clicked Skorpiostech Logo";
NSString *kHSKBeaconGetHandshakeURLTouch = @"Clicked GetHandshake URL";
NSString *kHSKBeaconCardReceivedEvent = @"Card Received";
NSString *kHSKBeaconBeginSendVcardEvent = @"Begin Send My Card";
NSString *kHSKCompleteSendVcardEvent = @"Complete Send My Card";
NSString *kHSKBeaconBrowsingForPeerEvent = @"Browsing for Peer";
NSString *kHSKBeaconBouncingCardEvent = @"Bouncing My Card";
NSString *kHSKBeaconBeginSendOtherVcardEvent = @"Begin Send Other Card";
NSString *kHSKCompleteSendOtherVcardEvent = @"Complete Send Other Card";
NSString *kHSKBeaconReceivedPictureEvent = @"Received a Picture";
NSString *kHSKBeaconBeginSendPictureEvent = @"Begin Send Picture";
NSString *kHSKCompleteSendPictureEvent = @"Complete Send Picture";
NSString *kHSKBeaconServerConnectionFailedEvent = @"Server Connection Failed";
NSString *kHSKBeaconServerConnectionSucceededEvent = @"Server Connection Succeeded";
NSString *kHSKBeaconServerBeginReconnectionEvent = @"Begin Server Reconnection";
NSString *kHSKBeaconMessageFailedEvent = @"Message Failed to Send";
NSString *kHSKBeaconSMSAppStoreLinkSendSuccess = @"SMS App Store Link Send Success";
NSString *kHSKBeaconSMSAppStoreLinkSendFail = @"SMS App Store Link Send Fail";
NSString *kHSKBeaconEmailCardEvent = @"Send Card via Email";
NSString *kHSKBeaconEmailPictureEvent = @"Send Picture via Email";
