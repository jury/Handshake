//
//  NSStream+SKPSMTPExtensions.h
//  SMTPSender
//
//  Created by Ian Baird on 10/28/08.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CFNetwork/CFNetwork.h>

@interface NSStream (SKPSMTPExtensions)

+ (void)getStreamsToHostNamed:(NSString *)hostName port:(NSInteger)port inputStream:(NSInputStream **)inputStream outputStream:(NSOutputStream **)outputStream;

@end
