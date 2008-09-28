//
//  CTouchDebugging.m
//  kcal
//
//  Created by Jonathan Wight on 03/31/08. Updated by Ian Baird.
//  Copyright 2008 Skorpiostech, Inc. All rights reserved.
//

#import "TouchDebugging.h"


#ifdef NDEBUG

typedef void (*LogCStringFunctionProc)(const char *string, unsigned length, BOOL withSyslogBanner);
extern LogCStringFunctionProc _NSLogCStringFunction(void);
extern void _NSSetLogCStringFunction(LogCStringFunctionProc proc);
static void MyNSLogCStringFunction(const char *string, unsigned length, BOOL withSyslogBanner);

static LogCStringFunctionProc sRealNSLogCStringFunction = NULL;

void __attribute__((constructor)) HackNSLog_Loader(void)
{
    if (sRealNSLogCStringFunction == NULL)
	{
        sRealNSLogCStringFunction = _NSLogCStringFunction();
        _NSSetLogCStringFunction(MyNSLogCStringFunction);
	}
}

static void MyNSLogCStringFunction(const char *string, unsigned length, BOOL withSyslogBanner)
{
    // Do nothing
    // fprintf(stderr, "%*s\n", length, string);
}

#endif
