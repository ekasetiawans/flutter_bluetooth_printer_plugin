part of flutter_bluetooth_printer_web;

class WebBlueoothDartDevice extends BluetoothDevice {
  final WebBluetoothDevice jsDevice;
  WebBlueoothDartDevice({
    required super.address,
    super.name,
    super.type,
    required this.jsDevice,
  });
}
