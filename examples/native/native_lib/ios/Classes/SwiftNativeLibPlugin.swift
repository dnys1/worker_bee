import Flutter
import UIKit

public class SwiftNativeLibPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "native_lib", binaryMessenger: registrar.messenger())
    let instance = SwiftNativeLibPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }

  public static func unused() {
    base64_encode_ffi(nil)
  }
}
