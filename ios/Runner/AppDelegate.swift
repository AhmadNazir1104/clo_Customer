import Flutter
import UIKit
import Firebase
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Register native ad factory after engine (and plugins) are initialised
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      engineBridge.pluginRegistry,
      factoryId: "listTile",
      nativeAdFactory: ListTileNativeAdFactory()
    )
  }
}
