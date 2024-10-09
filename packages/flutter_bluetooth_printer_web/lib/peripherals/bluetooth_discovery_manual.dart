part of '../flutter_bluetooth_printer_web_library.dart';

class BluetoothDiscoveryManual extends ChangeNotifier {
  BluetoothDiscoveryManual() {
    _bluetooth = web.window.navigator.bluetooth;
  }

  late final Bluetooth _bluetooth;

  bool isInitialized = false;

  final String generalServiceUuid = '000018f0-0000-1000-8000-00805f9b34fb';

  List<WebBlueoothDartDevice> devices = [];

  Stream<WebBlueoothDartDevice> discover() async* {
    if (!isInitialized) {
      isInitialized = true;
      final request = RequestDeviceJS(
        acceptAllDevices: true.toJS,
        optionalServices: [generalServiceUuid.toJS].toJS,
      );

      WebBluetoothDevice? device;

      try {
        device = await _bluetooth.requestDevice(request).toDart;
      } catch (e) {
        debugPrint(e.toString());
        device = null;
      }

      if (device != null) {
        devices.add(
          WebBlueoothDartDevice(
            address: device.id.toDart,
            jsDevice: device,
            name: device.name.toDart,
          ),
        );
      }

      yield* Stream.fromIterable(
        devices,
      );

      // try {
      //   final devices = await _bluetooth.getDevices().toDart;

      //   yield* Stream.fromIterable(
      //     devices.toDart.map(
      //       (e) => WebBlueoothDartDevice(
      //         address: e.id.toDart,
      //         jsDevice: e,
      //         name: e.name.toDart,
      //       ),
      //     ),
      //   );
      // } catch (e) {
      //   debugPrint(e.toString());
      // }
      return;
    }

    try {
      // final devices = await _bluetooth.getDevices().toDart;

      // yield* Stream.fromIterable(
      //   devices.toDart.map(
      //     (e) => WebBlueoothDartDevice(
      //       address: e.id.toDart,
      //       jsDevice: e,
      //       name: e.name.toDart,
      //     ),
      //   ),
      // );
      yield* Stream.fromIterable(
        devices,
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
