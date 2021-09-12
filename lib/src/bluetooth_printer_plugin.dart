import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_printer/src/bluetooth_device.dart';
import 'package:flutter_bluetooth_printer/src/esc_pos_utils.dart';
import 'package:image/image.dart';

class BluetoothPrinter {
  final _utility = PrinterUtils();
  static final instance = BluetoothPrinter._();
  final _channel = const MethodChannel('id.flutter.plugins/bluetooth_printer');

  BluetoothPrinter._();
  Future<bool> isEnabled() async {
    return await _channel.invokeMethod('isEnabled');
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    final res = await _channel.invokeMethod('getBondedDevices');
    return (res as List)
        .map((e) => BluetoothDevice(
              name: e['name'],
              address: e['address'],
              type: e['type'],
            ))
        .toList();
  }

  Future<void> print({
    required BluetoothDevice device,
    required Image image,
  }) async {
    final data = _utility.decodeImage(image);
    await _channel.invokeMethod(
      'print',
      {
        'address': device.address,
        'data': data,
      },
    );
  }
}
