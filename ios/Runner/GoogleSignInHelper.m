#import "GoogleSignInHelper.h"
#import <GoogleSignIn/GoogleSignIn.h>
#import <objc/runtime.h>

@implementation GoogleSignInHelper

static BOOL isConfigured = NO;
static NSString* cachedClientID = nil;

// Method using Swift naming convention
+ (void)configure:(NSString *)clientID {
    if (clientID == nil || clientID.length == 0) {
        NSLog(@"CardWizz ERROR: Invalid client ID provided");
        return;
    }
    
    NSLog(@"CardWizz: Configuring Google Sign-In with client ID: %@", clientID);

    // Keep this simple - no reflection or complex error handling
    @try {
        // Simple direct configuration
        GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:clientID];
        [GIDSignIn.sharedInstance setConfiguration:config];
        NSLog(@"CardWizz: Google Sign-In configured successfully");
    } @catch (NSException *exception) {
        NSLog(@"CardWizz ERROR: Exception during configuration: %@", exception);
    }
}

// Backward compatibility method
+ (void)configureWithClientID:(NSString *)clientID {
    [self configure:clientID];
}

// Simple URL handler
+ (BOOL)handle:(NSURL *)url {
    @try {
        return [GIDSignIn.sharedInstance handleURL:url];
    } @catch (NSException *exception) {
        NSLog(@"CardWizz ERROR: Exception handling URL: %@", exception);
        return NO;
    }
}

+ (BOOL)handleURL:(NSURL *)url {
    return [self handle:url];
}

@end
