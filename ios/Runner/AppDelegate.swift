import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // IMPORTANT: provideAPIKey must be called before any other Google Maps usage.
    // Hardcoded here because the .env asset-parsing approach can silently fail
    // (e.g. wrong bundle path on newer iOS) and the resulting nil key causes
    // the native GMSServices to crash with an uncaught exception when the
    // GoogleMap widget renders.
    GMSServices.setMetalRendererEnabled(true) // Better stability on iOS 26+ simulator
    GMSServices.provideAPIKey("AIzaSyBY1Gj_ddLcfJEa1k1b9BgzyBQDBLRB5cg")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
