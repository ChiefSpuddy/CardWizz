import UIKit
import Flutter
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Debug log to check if AppDelegate is initializing
    NSLog("CardWizz: AppDelegate initializing")
    
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // Remove native GoogleSignIn setup - we'll handle this differently
    
    // Setup method channel for testing
    setupMethodChannel()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Setup the method channel for native communication
  private func setupMethodChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      NSLog("CardWizz ERROR: Could not get FlutterViewController")
      return
    }
    
    // Create method channel
    methodChannel = FlutterMethodChannel(
      name: "com.cardwizz.app/auth",
      binaryMessenger: controller.binaryMessenger)
    
    // Add method call handler
    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      
      if call.method == "testGoogleSignIn" {
        self.testGoogleSignIn(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    NSLog("CardWizz: Method channel setup complete")
  }
  
  // Test Google Sign-In configuration
  private func testGoogleSignIn(result: @escaping FlutterResult) {
    NSLog("CardWizz: Testing Google Sign-In configuration")
    
    // Verify Google Sign-In is properly configured
    let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String
    
    if clientID == nil {
      NSLog("CardWizz ERROR: Missing GIDClientID in Info.plist")
      result(["error": "Missing GIDClientID in Info.plist"])
      return
    }
    
    // Check URL schemes
    if let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] {
      var foundScheme = false
      for urlType in urlTypes {
        if let schemes = urlType["CFBundleURLSchemes"] as? [String] {
          for scheme in schemes {
            if scheme.contains("googleusercontent") {
              foundScheme = true
              NSLog("CardWizz: Found Google URL scheme: \(scheme)")
            }
          }
        }
      }
      
      if !foundScheme {
        NSLog("CardWizz ERROR: No Google URL scheme found in Info.plist")
        result(["error": "No Google URL scheme found in Info.plist"])
        return
      }
    }
    
    // Always return success to allow app to continue
    result(["status": "Google Sign-In properly configured"])
  }
  
  // Handle URL scheme callbacks - This is the CRITICAL part for Google Sign-In
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    NSLog("CardWizz: Received URL callback: \(url.absoluteString)")
    
    // Let super implementation handle this - Flutter plugins will pick this up
    return super.application(app, open: url, options: options)
  }
}
