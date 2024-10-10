// ignore_for_file: avoid_print

part of '../flutter_bluetooth_printer_web_library.dart';

class WebUnknownState extends DiscoveryState {}

class WebPermissionRestrictedState extends DiscoveryState {}

class WebBluetoothDisabledState extends DiscoveryState {}

class WebUnsupportedBluetoothState extends DiscoveryState {}

class WebBluetoothEnabledState extends DiscoveryState {}

class WebDiscoveryResult extends DiscoveryState {
  final List<BluetoothDevice> devices;
  WebDiscoveryResult({required this.devices});
}

class FlutterBluetoothWebJSChannel extends FlutterBluetoothPrinterPlatform {
  FlutterBluetoothWebJSChannel() {
    _discoveryManual = BluetoothDiscoveryManual();
  }

  final StreamController<DiscoveryState> discoverState =
      StreamController.broadcast();

  late final BluetoothDiscoveryManual _discoveryManual;

  // isInitialized will be stored in sessionStorage or localStorage in the near future .
  bool isInitialized = false;

  static void registerWith(Registrar registrat) {
    FlutterBluetoothPrinterPlatform.instance = FlutterBluetoothWebJSChannel();
  }

  @override
  Future<BluetoothState> checkState() async {
    return BluetoothState.enabled;
  }

  @override
  Future<bool> connect(String address) => _discoveryManual.connect(address);

  @override
  Future<bool> disconnect(String address) =>
      _discoveryManual.disconnect(address);

  @override
  Stream<DiscoveryState> get discovery => _discoveryManual.discover();

  @override
  Future<bool> write({
    required String address,
    required Uint8List data,
    bool keepConnected = false,
    required int maxBufferSize,
    required int delayTime,
    ProgressCallback? onProgress,
  }) =>
      _discoveryManual.write(
        address: address,
        data: data,
        keepConnected: keepConnected,
        maxBufferSize: maxBufferSize,
        delayTime: delayTime,
        onProgress: onProgress,
      );
}
