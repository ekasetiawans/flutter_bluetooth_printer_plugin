part of '../flutter_bluetooth_printer_web_library.dart';

class WebBlueoothDartDevice extends BluetoothDevice {
  final WebBluetoothDevice jsDevice;
  WebBlueoothDartDevice({
    required super.address,
    super.name,
    super.type,
    required this.jsDevice,
  });
}
