#import <Foundation/Foundation.h>

@interface GoogleSignInHelper : NSObject

// Fix method names to match Swift's expectations
+ (void)configure:(NSString *)clientID;
+ (void)configureWithClientID:(NSString *)clientID; // For backward compatibility
+ (BOOL)handle:(NSURL *)url;

@end
