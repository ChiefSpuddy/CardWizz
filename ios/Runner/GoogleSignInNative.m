#import "GoogleSignInNative.h"
#import <GoogleSignIn/GoogleSignIn.h>

@interface GoogleSignInNative () <GIDSignInDelegate>
@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, copy) FlutterResult pendingResult;
@end

@implementation GoogleSignInNative

+ (instancetype)sharedInstance {
    static GoogleSignInNative *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GoogleSignInNative alloc] init];
    });
    return instance;
}

- (void)setupWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self.channel = [FlutterMethodChannel methodChannelWithName:@"com.cardwizz.google_sign_in"
                                              binaryMessenger:[registrar messenger]];
    
    __weak typeof(self) weakSelf = self;
    [self.channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        [weakSelf handleMethodCall:call result:result];
    }];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSLog(@"GoogleSignInNative: Received method call: %@", call.method);
    
    if ([@"init" isEqualToString:call.method]) {
        [self initializeWithClientId:call.arguments[@"clientId"] result:result];
    } else if ([@"signIn" isEqualToString:call.method]) {
        [self signInWithResult:result];
    } else if ([@"signOut" isEqualToString:call.method]) {
        [self signOutWithResult:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)initializeWithClientId:(NSString *)clientId result:(FlutterResult)result {
    NSLog(@"GoogleSignInNative: Initializing with client ID: %@", clientId);
    
    if (!clientId || clientId.length == 0) {
        // Try to get from Info.plist
        clientId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GIDClientID"];
        if (!clientId) {
            result([FlutterError errorWithCode:@"MISSING_CLIENT_ID" 
                                      message:@"Client ID is required" 
                                      details:nil]);
            return;
        }
    }
    
    // Configure Google Sign-In
    GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:clientId];
    [GIDSignIn.sharedInstance setConfiguration:config];

    // Set the delegate
    if ([GIDSignIn.sharedInstance respondsToSelector:@selector(setDelegate:)]) {
        [GIDSignIn.sharedInstance performSelector:@selector(setDelegate:) withObject:self];
    }
    
    result(@YES);
}

- (void)signInWithResult:(FlutterResult)result {
    NSLog(@"GoogleSignInNative: Attempting sign in");
    self.pendingResult = result;
    
    // Check if we have a valid configuration
    if (![GIDSignIn.sharedInstance respondsToSelector:@selector(configuration)] ||
        ![[GIDSignIn.sharedInstance performSelector:@selector(configuration)] isKindOfClass:[GIDConfiguration class]]) {
        
        // Configuration not set, try to set it
        NSString *clientId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GIDClientID"];
        if (clientId) {
            GIDConfiguration *config = [[GIDConfiguration alloc] initWithClientID:clientId];
            [GIDSignIn.sharedInstance setConfiguration:config];
        } else {
            result([FlutterError errorWithCode:@"SIGN_IN_FAILED" 
                                      message:@"Google Sign-In not configured" 
                                      details:nil]);
            self.pendingResult = nil;
            return;
        }
    }
    
    // Present the sign-in UI
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    
    [GIDSignIn.sharedInstance signInWithPresentingViewController:viewController
                                                      completion:^(GIDSignInResult * _Nullable signInResult, NSError * _Nullable error) {
        if (error) {
            NSLog(@"GoogleSignInNative: Error signing in: %@", error);
            self.pendingResult([FlutterError errorWithCode:@"SIGN_IN_FAILED" 
                                                  message:error.localizedDescription 
                                                  details:nil]);
        } else if (signInResult) {
            NSMutableDictionary *userData = [NSMutableDictionary dictionary];
            userData[@"id"] = signInResult.user.userID;
            userData[@"email"] = signInResult.user.profile.email;
            userData[@"displayName"] = signInResult.user.profile.name;
            userData[@"photoUrl"] = signInResult.user.profile.imageURL.absoluteString;
            userData[@"idToken"] = signInResult.user.idToken.tokenString;
            
            self.pendingResult(userData);
        } else {
            self.pendingResult(nil);
        }
        self.pendingResult = nil;
    }];
}

- (void)signOutWithResult:(FlutterResult)result {
    NSLog(@"GoogleSignInNative: Signing out");
    
    [GIDSignIn.sharedInstance signOut];
    result(@YES);
}

// GIDSignInDelegate methods
- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    // This is for older versions of Google Sign-In
    if (!self.pendingResult) return;
    
    if (error) {
        self.pendingResult([FlutterError errorWithCode:@"SIGN_IN_FAILED" 
                                              message:error.localizedDescription 
                                              details:nil]);
    } else {
        NSMutableDictionary *userData = [NSMutableDictionary dictionary];
        userData[@"id"] = user.userID;
        userData[@"email"] = user.profile.email;
        userData[@"displayName"] = user.profile.name;
        userData[@"photoUrl"] = user.profile.imageURL.absoluteString;
        userData[@"idToken"] = user.authentication.idToken;
        
        self.pendingResult(userData);
    }
    self.pendingResult = nil;
}

@end
