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

enum BluetoothState {
  unknown, //0
  disabled, //1
  enabled, //2
  notPermitted, //3
  permitted, //4
}

abstract class DiscoveryState {}

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

  Stream<DiscoveryState> get discovery;

  Future<bool> write({
    required String address,
    required Uint8List data,
    bool keepConnected = false,
    required int maxBufferSize,
    required int delayTime,
    ProgressCallback? onProgress,
  });

  Future<bool> connect(String address);
  Future<bool> disconnect(String address);
  Future<BluetoothState> checkState();
}

class BluetoothDevice extends DiscoveryState {
  final String address;
  final String? name;
  final int? type;

  BluetoothDevice({
    required this.address,
    this.name,
    this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDevice && other.address == address;

  @override
  int get hashCode => address.hashCode;
}
