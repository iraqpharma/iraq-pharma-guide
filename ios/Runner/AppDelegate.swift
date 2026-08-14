import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Without this the device never obtains an APNs device token, so
    // FirebaseMessaging.getToken() always failed with apns-token-not-set and
    // no FCM token was ever produced on iOS. This call is silent — the
    // permission prompt comes from requestAuthorization, not from here.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // The number on the app icon is set by the push payload at delivery time
    // and never changes afterwards, so it stayed visible after the user had
    // already read everything. Dart drives it explicitly through this channel.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppBadgeChannel") {
      let channel = FlutterMethodChannel(
        name: "iraqpharma/badge",
        binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "setBadge" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let args = call.arguments as? [String: Any]
        let count = args?["count"] as? Int ?? 0
        if #available(iOS 16.0, *) {
          UNUserNotificationCenter.current().setBadgeCount(count)
        } else {
          UIApplication.shared.applicationIconBadgeNumber = count
        }
        result(nil)
      }
    }
  }
}
