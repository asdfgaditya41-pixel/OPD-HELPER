import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let envPath = Bundle.main.path(forResource: "flutter_assets/.env", ofType: nil) {
      if let envStr = try? String(contentsOfFile: envPath) {
        for line in envStr.components(separatedBy: .newlines) {
          let parts = line.components(separatedBy: "=")
          if parts.count >= 2 && parts[0].trimmingCharacters(in: .whitespaces) == "GOOGLE_MAPS_API_KEY" {
            let key = parts.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespaces)
            GMSServices.provideAPIKey(key)
          }
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
