import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_bluetooth_printer_method_channel.dart';

abstract class FlutterBluetoothPrinterPlatform extends PlatformInterface {
  /// Constructs a FlutterBluetoothPrinterPlatform.
  FlutterBluetoothPrinterPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterBluetoothPrinterPlatform _instance =
      MethodChannelFlutterBluetoothPrinter();

  /// The default instance of [FlutterBluetoothPrinterPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterBluetoothPrinter].
  static FlutterBluetoothPrinterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterBluetoothPrinterPlatform] when
  /// they register themselves.
  static set instance(FlutterBluetoothPrinterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
