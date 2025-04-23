import UIKit
import Flutter
import CoreMotion

@main
@objc class AppDelegate: FlutterAppDelegate {
  let motionManager = CMMotionActivityManager()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "motion_permission", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "checkMotionPermissionStatus":
        let askedBefore = UserDefaults.standard.bool(forKey: "motionPermissionAsked")
        result(askedBefore)
      case "requestMotionPermission":
        self?.requestMotionPermission(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func requestMotionPermission(result: @escaping FlutterResult) {
    motionManager.queryActivityStarting(from: Date(), to: Date(), to: .main) { activities, error in
      UserDefaults.standard.set(true, forKey: "motionPermissionAsked")
      if let err = error as NSError?, err.code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
        result(false)
      } else {
        result(true)
      }
    }
  }
}