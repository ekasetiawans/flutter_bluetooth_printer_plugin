import Flutter
import UIKit

public class SwiftFlutterBluetoothPrinterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, PrinterManagerDelegate {


    static var instance: SwiftFlutterBluetoothPrinterPlugin?
    private let channel: FlutterMethodChannel
    private let discoveryChannel: FlutterEventChannel
    private var _bluetoothPrinterManager: BluetoothPrinterManager?
    private var bluetoothPrinterManager: BluetoothPrinterManager {
        get {
            return _bluetoothPrinterManager!
        }
    }

    public init(binaryMessenger: FlutterBinaryMessenger){
        self.channel = FlutterMethodChannel(name: "maseka.dev/flutter_bluetooth_printer", binaryMessenger: binaryMessenger)
        self.discoveryChannel = FlutterEventChannel(name: "maseka.dev/flutter_bluetooth_printer/discovery", binaryMessenger: binaryMessenger)


        super.init()
        self.channel.setMethodCallHandler(handle)
        self.discoveryChannel.setStreamHandler(self)
    }


    private func ensureManager(cb: ((Bool) ->())? = nil){
        if (_bluetoothPrinterManager != nil){
            if (_bluetoothPrinterManager!.isAvailable){
                cb?(true)
                return
            }

            cb?(false)
            return
        }

        self._bluetoothPrinterManager = BluetoothPrinterManager(
            didInitialized: { (state) in
                if (state == .poweredOn){
                    cb?(true)
                    return
                }

                cb?(false)
            })

        self._bluetoothPrinterManager!.delegate = self
    }

  public static func register(with registrar: FlutterPluginRegistrar) {
      SwiftFlutterBluetoothPrinterPlugin.instance = SwiftFlutterBluetoothPrinterPlugin(binaryMessenger: registrar.messenger())
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      ensureManager {
          (_) in

          switch (call.method){
          case "getState":
              if (!self.bluetoothPrinterManager.isAvailable){
                  result(1)
                  return
              }

              if (!self.bluetoothPrinterManager.isPermitted){
                  result(3)
                  return
              }

              result(2)
              break

          case "connect":
              let parameter = call.arguments as! NSDictionary
              let address = parameter["address"] as! NSString

              let devices = self.bluetoothPrinterManager.nearbyPrinters
              var device: BluetoothPrinter?
              for item in devices {
                  if (item.identifier.uuidString == address as String){
                      device = item
                      break
                  }
              }

              if (device == nil) {
                  result(false)
                  return
              }

              if device?.state != .connected {
                  self.bluetoothPrinterManager.connect(device!) {
                      result(true)
                  } didError: {
                      result(false)
                  }
                  return
              }


              result(true)
              break

          case "disconnect":
              let parameter = call.arguments as! NSDictionary
              let address = parameter["address"] as! NSString

              let devices = self.bluetoothPrinterManager.nearbyPrinters
              var device: BluetoothPrinter?
              for item in devices {
                  if (item.identifier.uuidString == address as String){
                      device = item
                      break
                  }
              }

              if (device == nil) {
                  result(false)
                  return
              }

              if device?.state == .connected {
                  self.bluetoothPrinterManager.disconnect(device!)
                  result(true)
                  return
              }

              result(false)
              break

          case "write":
              let parameter = call.arguments as! NSDictionary
              let address = parameter["address"] as! NSString
              let data = parameter["data"] as! FlutterStandardTypedData
              let keepConnected = ((parameter["keep_connected"] as? Bool?) ?? false)!

              let devices = self.bluetoothPrinterManager.nearbyPrinters
              var device: BluetoothPrinter?
              for item in devices {
                  if (item.identifier.uuidString == address as String){
                      device = item
                      break
                  }
              }

              if (device == nil) {
                  result(false)
                  return
              }

              self.channel.invokeMethod("didUpdateState", arguments: 1)
              self.bluetoothPrinterManager.connect(device!) {
                  if self.bluetoothPrinterManager.canPrint {
                      let receipt = Receipt(data: data.data)
                      self.bluetoothPrinterManager.print(receipt,
                                                         progressBlock: { (sent, total) in
                          let data:[String:Any] = ["total": total, "progress": sent]
                          self.channel.invokeMethod("onPrintingProgress", arguments: data)
                      }, completeBlock:  { (error) in
                          if (error != nil){
                              result(false)
                              if (!keepConnected){
                                  self.bluetoothPrinterManager.disconnect(device!)
                              }

                              self.channel.invokeMethod("didUpdateState", arguments: 3)
                              return
                          }

                          result(true)
                          if (!keepConnected){
                              self.bluetoothPrinterManager.disconnect(device!)
                          }
                          self.channel.invokeMethod("didUpdateState", arguments: 3)
                      })
                  } else {
                      result(false)
                      if (!keepConnected){
                          self.bluetoothPrinterManager.disconnect(device!)
                      }
                      self.channel.invokeMethod("didUpdateState", arguments: 3)
                  }
              } didError: {
                  result(false)
              }
              break

          default:
              result(FlutterMethodNotImplemented)
          }
      }


  }


    private var eventSink: FlutterEventSink?
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        ensureManager {
            (state) in
            self.eventSink = events

            self.bluetoothPrinterManager.stopScan()
            let err = self.bluetoothPrinterManager.startScan()
            if err == .deviceNotReady {
                return
            }

            for item in self.bluetoothPrinterManager.nearbyPrinters {
                let device = self.deviceToMap(printer: item)
                self.eventSink?(device)
            }
        }

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        bluetoothPrinterManager.stopScan()
        return nil
    }

    public func nearbyPrinterDidChange(_ change: NearbyPrinterChange) {
        switch change {
        case .add(let printer):
            let device = deviceToMap(printer: printer)
            self.eventSink?(device)
            break
        case .update(let printer):
            let device = deviceToMap(printer: printer)
            self.eventSink?(device)
            break
        case .remove(_):
            break
        }
    }

    private func deviceToMap(printer: BluetoothPrinter) -> Dictionary<String, Any?> {
        let isConnected = printer.state == .connected
        let result:[String: Any?] = ["code": 4, "address": printer.identifier.uuidString, "name": printer.name, "is_connected": isConnected]
        return result
    }
}
