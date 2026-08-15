import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // NOTE: registerForRemoteNotifications() must NOT be called here.
    //
    // With the implicit-engine lifecycle, GeneratedPluginRegistrant runs in
    // didInitializeImplicitFlutterEngine — i.e. AFTER this method. Calling
    // registerForRemoteNotifications() from here asks iOS for the APNs device
    // token before FirebaseApp.configure() has run and before the Messaging
    // plugin has installed its app-delegate hooks, so when iOS delivers
    // didRegisterForRemoteNotificationsWithDeviceToken there is nobody to hand
    // the token to. Messaging.apnsToken then stays nil for the whole session,
    // getAPNSToken() returns NULL forever, getToken() never yields an FCM
    // token, and no row is ever written to profiles.fcm_token — on iOS only,
    // for every account. The registration call now lives at the end of
    // didInitializeImplicitFlutterEngine, once the plugins are listening.
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

    // Now that Firebase is configured and FirebaseMessaging's delegate hooks
    // are in place, it is safe to ask iOS for the APNs device token. This call
    // is silent: the permission dialog comes from requestAuthorization, never
    // from here.
    UIApplication.shared.registerForRemoteNotifications()
  }
}
