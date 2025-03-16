#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

@interface GoogleSignInNative : NSObject

+ (instancetype)sharedInstance;
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)setupWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;

@end

// Add plugin class declaration for registration
@interface GoogleSignInNativePlugin : NSObject<FlutterPlugin>
@end
