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
  FlutterBluetoothWebJSChannel();

  final StreamController<DiscoveryState> discoverState = StreamController();

  // isInitialized will be stored in sessionStorage or localStorage in the near future .
  bool isInitialized = false;

  static void registerWith(Registrar registrat) {
    FlutterBluetoothPrinterPlatform.instance = FlutterBluetoothWebJSChannel();
  }

  @override
  Future<BluetoothState> checkState() {
    // TODO: implement checkState
    throw UnimplementedError();
  }

  @override
  Future<bool> connect(String address) {
    // TODO: implement connect
    throw UnimplementedError();
  }

  @override
  Future<bool> disconnect(String address) {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  Stream<DiscoveryState> get discovery => _discoverDevices();

  Stream<DiscoveryState> _discoverDevices() async* {
    final nav = web.window.navigator;

    try {
      if (!isInitialized) {
        isInitialized = true;
        // 1. Add received stream listener here .
        // 2. requestDevice, and pair them so that discovery can find device that you wanted .
        // 3. requestLEScan after device is paired .
        // 4. Test and see the result .
        return;
      }

      // 1. requestLEScan, so that you can find discovery for them .
      // 2. Test and see result .

      const String generalServiceUuid = '000018f0-0000-1000-8000-00805f9b34fb';
      // const String defaultServiceCharUuid =
      //     '00002af1-0000-1000-8000-00805f9b34fb';

      nav.bluetooth.advertisementReceivedStream.listen(
        (AdvertisementDeviceResult event) {
          print('Current Device : ${event.device.name.toDart.toString()}');
          discoverState.sink.add(
            WebDiscoveryResult(
              devices: [
                BluetoothDevice(
                  address: event.device.id.toDart,
                  name: event.device.name.toDart,
                  type: event.appearance,
                ),
              ],
            ),
          );
        },
      );

      final newRequest = LEScanRequest(
        acceptAllAdvertisements: false.toJS,
        listenOnlyGrantedDevices: true.toJS,
        keepRepeatedDevices: true.toJS,
        filters: [
          ScanFilterJSObject(
            services: [generalServiceUuid.toJS].toJS,
          )
        ].toJS,
      );

      nav.bluetooth.requestLEScan(newRequest).toDart.then(
            (value) {},
          );

      final request = RequestDeviceJS(
        acceptAllDevices: true.toJS,
        optionalServices: [generalServiceUuid.toJS].toJS,
      );

      // Pairing device so that Advertisement can catch device result .
      nav.bluetooth.requestDevice(request).toDart.then((v) {
        nav.bluetooth.requestLEScan(newRequest).toDart.then(
          (value) {
            // scanTimer = Timer(const Duration(seconds: 10), () {
            //   value.stop();
            //   scanTimer.cancel();
            // });
          },
        );
      });

      yield* discoverState.stream;
    } catch (e) {
      debugPrint('Error : ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<bool> write({
    required String address,
    required Uint8List data,
    bool keepConnected = false,
    required int maxBufferSize,
    required int delayTime,
    ProgressCallback? onProgress,
  }) {
    // TODO: implement write
    throw UnimplementedError();
  }
}
