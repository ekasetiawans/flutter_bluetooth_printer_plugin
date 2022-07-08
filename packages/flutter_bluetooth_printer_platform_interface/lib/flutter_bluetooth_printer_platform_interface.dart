library flutter_bluetooth_printer_platform_interface;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

typedef ProgressCallback = void Function(int total, int sent);

enum BluetoothConnectionState {
  idle,
  connecting,
  printing,
  completed,
}

abstract class FlutterBluetoothPrinterPlatform extends PlatformInterface {
  static final Object _token = Object();
  static late FlutterBluetoothPrinterPlatform _instance;
  FlutterBluetoothPrinterPlatform() : super(token: _token);

  static FlutterBluetoothPrinterPlatform get instance => _instance;
  static set instance(FlutterBluetoothPrinterPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  final connectionStateNotifier = ValueNotifier<BluetoothConnectionState>(
    BluetoothConnectionState.idle,
  );

  Stream<BluetoothDevice> get discovery;
  Future<void> write({
    required String address,
    required Uint8List data,
    ProgressCallback? onProgress,
  });
}

class BluetoothDevice {
  final String address;
  final String name;
  final int type;

  const BluetoothDevice({
    required this.address,
    required this.name,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDevice && other.address == address;

  @override
  int get hashCode => address.hashCode;
}
