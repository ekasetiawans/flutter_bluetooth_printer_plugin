import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_printer/src/bluetooth_device.dart';
import 'package:flutter_bluetooth_printer/src/esc_pos_utils.dart';
import 'package:image/image.dart' as img;

class BluetoothPrinter {
  final _utility = PrinterUtils();
  static final instance = BluetoothPrinter._();
  final _channel = const MethodChannel('id.flutter.plugins/bluetooth_printer');

  final _discoverController =
      StreamController<List<BluetoothDevice>>.broadcast();

  final _devices = <BluetoothDevice>[];
  Stream<List<BluetoothDevice>> get devices {
    return _getDevices().asBroadcastStream();
  }

  Stream<List<BluetoothDevice>> _getDevices() async* {
    yield _devices;

    await for (var devices in _discoverController.stream) {
      yield devices;
    }
  }

  BluetoothPrinter._() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'didDiscover':
          final dev = call.arguments;
          final device = BluetoothDevice(
            name: dev['name'],
            address: dev['address'],
            type: dev['type'],
          );

          if (!_devices.any((element) => element.address == device.address)) {
            _devices.add(device);
            _discoverController.sink.add(_devices);
          }
          break;
        default:
      }

      return true;
    });
  }

  Future<bool> isEnabled() async {
    return await _channel.invokeMethod('isEnabled');
  }

  Future<void> startScan() async {
    _devices.clear();
    await _channel.invokeMethod('startScan');
  }

  Future<void> stopScan() async {
    await _channel.invokeMethod('stopScan');
    _devices.clear();
  }

  Future<void> printCommands({
    required BluetoothDevice device,
    required List<Uint8List> commands,
  }) async {
    await _channel.invokeMethod(
      'print',
      {
        'address': device.address,
        'data': commands,
      },
    );
  }

  Future<void> printImage({
    required BluetoothDevice device,
    required img.Image image,
  }) async {
    final data = _utility.decodeImageInChunks(image);
    await printCommands(
      device: device,
      commands: data.map((e) => Uint8List.fromList(e)).toList(),
    );
  }
}
