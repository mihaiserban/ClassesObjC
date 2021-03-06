#import "SSWebBrowsing.h"
#import "NSBundle+MainApp.h"

@implementation NSString (FirefoxQuicksearch)

+ (CFURLRef)sampleHttpUrl {
	return (CFURLRef)[NSURL URLWithString:@"http://xx.xx"] ;
}

- (NSString*)stringByFixingFirefoxQuicksearch {
	NSString* output ;
	
	if ([self hasSuffix:@"%s"])
	{
		// This is one of Firefox' QuickSearches 
		// For examaple: "Type "dict <word>" in the location bar to perform a dictionary look-up"
		// -URLWithString will fail with this, I suppose because the % at the end of its url is not allowed per some RFC.
		// So, first we replace %s with our app name,
		NSMutableString* temp = [self mutableCopy] ;
		[temp replaceOccurrencesOfString:@"%s"
							  withString:[[NSBundle mainAppBundle] objectForInfoDictionaryKey:@"CFBundleName"]
								 options:NSBackwardsSearch
								   range:NSMakeRange(0, [temp length])] ;
		output =  [NSString stringWithString:temp] ;
		// I tried removing with query (which wasn't easy because NSURL wouldn't initWithString until
		// I first replaced %s with the app name).  But this caused an "Internal Server Error" at
		// answers.com, either with or without the ? query delimiter character.
		[temp release] ;
	}
	else {
		output = self ;
	}
	
	return output ;
}

@end


@implementation SSWebBrowsing

+ (CFURLRef)sampleHttpUrl {
	return (CFURLRef)[NSURL URLWithString:@"http://xx.xx"] ;
}

+ (NSString*)defaultBrowserDisplayName {
	OSStatus err ;

	// Get browser's URL
	NSURL *defaultBrowserURL = nil ;
	err = LSGetApplicationForURL(
								 [self sampleHttpUrl],
								 kLSRolesViewer,
								 NULL,
								 (CFURLRef *)&defaultBrowserURL) ;
	NSString* name = nil ;
	if ((err == noErr) && defaultBrowserURL) {
		name = [[NSFileManager defaultManager] displayNameAtPath:[defaultBrowserURL path]] ;
		// Remove suffix ".app":
		if ([name hasSuffix:@".app"]) {
			// This was not necessary in Mac OS 10.3.
			name = [name substringToIndex:([name length] - 4)] ;
		}
	}
	if (!name) {
		name = @"??" ;
	}
    
    // Memory leak fixed in BookMacster 1.17.  See LSGetApplicationForURL() doc.
    if (defaultBrowserURL) {
        CFRelease(defaultBrowserURL) ;
    }
	
	return name ;
}

+ (NSString*)defaultBrowserBundleIdentifier {
	OSStatus err ;
	
	// Get browser's FSRef
	FSRef fsRef  ;
	err = LSGetApplicationForURL(
								 [self sampleHttpUrl],
								 kLSRolesViewer,
								 &fsRef,
								 NULL) ;
	
	// Get pathC (path C string)
	char pathC[2048] ;
	if (err == noErr) {
		err = FSRefMakePath(&fsRef, (UInt8*)pathC, 2048) ;
	}
	else {
		NSLog(@"Internal Error 324-2398.  Could not get URL for default web browser.") ;
		strcpy(pathC, "") ;
	}
	
	// Get path (NSString*)
	NSString* path = nil ;
	if (err == noErr) {
		path = [NSString stringWithCString:pathC
								  encoding:NSUTF8StringEncoding] ;
	}
	else {
		NSLog(@"Internal Error 324-5847.  Could not get pathC for default web browser") ;
	}
	
	// Get bundle
	NSBundle* bundle = nil ;
	if (path) {
		bundle = [NSBundle bundleWithPath:(NSString*)path] ;
	}
	else {
		NSLog(@"Internal Error 324-8547.  Could not path for default web browser %s", pathC) ;
	}
	
	// Get bundleIdentifier
	NSString* bundleIdentifier = nil ;
	if (bundle) {
		bundleIdentifier = [bundle bundleIdentifier] ;
	}
	else {
		NSLog(@"Internal Error 324-2563.  Could not get bundle for default web browser %@", path) ;
	}
	
	if (!bundleIdentifier) {
		NSLog(@"Internal Error 324-4785.  Could not get bundleIdentifier for default web browser %@", bundle) ;
		bundleIdentifier = @"" ;
	}
	
	return bundleIdentifier ;
}


+ (void)browseToURLString:(NSString*)urlString
  browserBundleIdentifier:(NSString*)browserBundleIdentifier
				 activate:(BOOL)activate {
	NSWorkspaceLaunchOptions options = NSWorkspaceLaunchAsync ;
	if (!activate) {
		options = options | NSWorkspaceLaunchWithoutActivation ;
	}
	
	if (!browserBundleIdentifier) {
		// Documentation for openURLs:withAppBundleIdentifier:options:additionalEventParamDescriptor:launchIdentifiers:
		// says that the app in the "default system binding" will be used if argument withAppBundleIdentifier is
		// an empty string.  However, it was found that this is not in general the desired default web browser!
		// It is instead the user's "open with" for .html files, which some users may have incorrectly set
		// to a non-web-browser application such as Preview or BBEdit.  Fixed in Bookdog 4.3.13:
		browserBundleIdentifier = [self defaultBrowserBundleIdentifier] ;
	}
	
	NSURL* url = nil ;
	if (urlString) {
		urlString = [urlString stringByFixingFirefoxQuicksearch] ;
		url = [NSURL URLWithString:urlString] ;
	}
	
	if (url) {
		NSArray* urls = [NSArray arrayWithObject:url] ;
		
		[[NSWorkspace sharedWorkspace] openURLs:urls
						withAppBundleIdentifier:browserBundleIdentifier
										options:options
				 additionalEventParamDescriptor:nil
							  launchIdentifiers:NULL] ;
	}
	else {
		// Starting in BookMacster 1.15, we NSBeep() here instead of logging
        // Internal Error 324-6754.  This happens if we are passed an invalid
        // URL such as a JavaScript bookmarklet, for example…
        //    javascript:var%20wRWMain1=window.open('','RefWorksBookmark');d=document;i='AddToRWScript';if(d.getElementById(i))RWAddToRW1();else{s=d.createElement('script');s.type='text/javascript';s.src='http://www.refworks.com/refworks/include/addtorw.asp';s.id=i;d.getElementsByTagName('head')[0].appendChild(s);}void(0);
        if (NSApp) {
            NSBeep() ;
        }
	}
	
	//	openURLs
	//	NSString* source ;
	//	NSDictionary* errorDic ;
	//	NSAppleScript* script ;
	//
	//	if (activate) {
	//		source = [[NSString alloc] initWithFormat:@"tell application \"Safari\"\nactivate\nend tell"] ;
	//		script = [[NSAppleScript alloc] initWithSource:source] ;
	//		[script executeAndReturnError:&errorDic] ;
	//		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]] ;
	//		[source release] ;
	//		[script release] ;
	//	}
	//
	//	source = [[NSString alloc] initWithFormat:@"tell application \"Safari\"\nmake new document\nset URL of result to \"%@\"\nend tell", url] ;
	//	script = [[NSAppleScript alloc] initWithSource:source] ;
	//	[script executeAndReturnError:&errorDic] ;
	//	[source release] ;
	//	[script release] ;
}

+ (NSImage*)faviconForDomain:(NSString*)domain {
	NSString* urlString = [[NSString alloc] initWithFormat:
						   @"http://%@/favicon.ico", domain] ;	
	NSImage* favicon = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:urlString]] ;
	[urlString release] ;
	
	return [favicon autorelease] ;
}	

@end