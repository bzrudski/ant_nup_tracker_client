import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    guard let mapsAPIKey = Bundle.main.object(forInfoDictionaryKey: "Google Maps API Key") as? String else {
        fatalError("Maps API key not found!")
    }
    GMSServices.provideAPIKey(mapsAPIKey)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
