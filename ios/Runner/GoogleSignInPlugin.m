#import <Flutter/Flutter.h>
#import "GoogleSignInNative.h"

// This will register our plugin
@implementation GoogleSignInNativePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [[GoogleSignInNative sharedInstance] setupWithRegistrar:registrar];
}

@end
