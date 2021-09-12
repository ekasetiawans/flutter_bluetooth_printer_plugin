import Flutter
import UIKit

public class SwiftFlutterBluetoothPrinterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "id.flutter.plugins/bluetooth_printer", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterBluetoothPrinterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
