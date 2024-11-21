// // ignore_for_file: avoid_print

// part of '../flutter_bluetooth_printer_web_library.dart';

// class WebUnknownState extends DiscoveryState {}

// class WebPermissionRestrictedState extends DiscoveryState {}

// class WebBluetoothDisabledState extends DiscoveryState {}

// class WebUnsupportedBluetoothState extends DiscoveryState {}

// class WebBluetoothEnabledState extends DiscoveryState {}

// class WebDiscoveryResult extends DiscoveryState {
//   final List<BluetoothDevice> devices;
//   WebDiscoveryResult({required this.devices});
// }

// class FlutterBluetoothWebJSChannel extends FlutterBluetoothPrinterPlatform {
//   FlutterBluetoothWebJSChannel();

//   final StreamController<DiscoveryState> discoverState =
//       StreamController.broadcast();

//   // isInitialized will be stored in sessionStorage or localStorage in the near future .
//   bool isInitialized = false;

//   static void registerWith(Registrar registrat) {
//     FlutterBluetoothPrinterPlatform.instance = FlutterBluetoothWebJSChannel();
//   }

//   @override
//   Future<BluetoothState> checkState() async {
//     return BluetoothState.enabled;
//   }

//   @override
//   Future<bool> connect(String address) {
//     // TODO: implement connect
//     throw UnimplementedError();
//   }

//   @override
//   Future<bool> disconnect(String address) {
//     // TODO: implement disconnect
//     throw UnimplementedError();
//   }

//   @override
//   Stream<DiscoveryState> get discovery =>
//       _isInDiscoverMode ? discoverState.stream : _discoverDevices();

//   bool _isInDiscoverMode = false;

//   Stream<DiscoveryState> _discoverDevices() async* {
//     final nav = web.window.navigator;

//     if (_isInDiscoverMode) {
//       return;
//     }

//     LEScanResult? result;

//     try {
//       _isInDiscoverMode = true;
//       if (!isInitialized) {
//         isInitialized = true;

//         web.window.navigator.bluetooth.advertisementReceivedStream.listen(
//           (AdvertisementDeviceResult event) {
//             print('Current Device : ${event.device.name.toDart.toString()}');
//             discoverState.sink.add(
//               WebDiscoveryResult(
//                 devices: [
//                   BluetoothDevice(
//                     address: event.device.id.toDart,
//                     name: event.device.name.toDart,
//                     type: event.appearance,
//                   ),
//                 ],
//               ),
//             );
//           },
//         );

//         const String generalServiceUuid =
//             '000018f0-0000-1000-8000-00805f9b34fb';
//         // const String defaultServiceCharUuid =
//         //     '00002af1-0000-1000-8000-00805f9b34fb';

//         final newRequest = LEScanRequest(
//           acceptAllAdvertisements: false.toJS,
//           listenOnlyGrantedDevices: true.toJS,
//           keepRepeatedDevices: true.toJS,
//           filters: [
//             ScanFilterJSObject(
//               services: [generalServiceUuid.toJS].toJS,
//             )
//           ].toJS,
//         );

//         nav.bluetooth.requestLEScan(newRequest).toDart.then(
//               (value) {},
//             );

//         final request = RequestDeviceJS(
//           acceptAllDevices: true.toJS,
//           optionalServices: [generalServiceUuid.toJS].toJS,
//         );

//         // Pairing device so that Advertisement can catch device result .
//         nav.bluetooth.requestDevice(request).toDart.then((v) {
//           nav.bluetooth.requestLEScan(newRequest).toDart.then(
//             (value) {
//               result = value;
//             },
//           );
//         });

//         yield* discoverState.stream;
//         return;
//       }

//       // 1. requestLEScan, so that you can find discovery for them .
//       // 2. Test and see result .

//       yield* discoverState.stream;
//     } catch (e) {
//       debugPrint('Error : ${e.toString()}');
//       rethrow;
//     } finally {
//       if (_isInDiscoverMode) {
//         if (result != null && result!.active.toDart) {
//           Timer(
//             const Duration(seconds: 10),
//             () {
//               result!.stop();
//             },
//           );
//         }
//       }

//       _isInDiscoverMode = false;
//     }
//   }

//   @override
//   Future<bool> write({
//     required String address,
//     required Uint8List data,
//     bool keepConnected = false,
//     required int maxBufferSize,
//     required int delayTime,
//     ProgressCallback? onProgress,
//   }) {
//     // TODO: implement write
//     throw UnimplementedError();
//   }
// }
