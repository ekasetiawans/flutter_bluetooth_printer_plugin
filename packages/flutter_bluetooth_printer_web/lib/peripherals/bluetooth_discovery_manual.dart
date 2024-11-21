part of flutter_bluetooth_printer_web;

class BluetoothDiscoveryManual extends ChangeNotifier {
  BluetoothDiscoveryManual() {
    _bluetooth = web.window.navigator.bluetooth;
  }

  late final Bluetooth _bluetooth;

  bool isInitialized = false;

  final String generalServiceUuid = '000018f0-0000-1000-8000-00805f9b34fb';
  final String defaultCharUuid = '00002af1-0000-1000-8000-00805f9b34fb';

  List<WebBlueoothDartDevice> devices = [];

  /// Write byte array to specified Service -> Characteristics .
  ///
  /// Currently Service specified to Write character into Print Service / Print Characteristic command .
  ///
  Future<bool> write({
    required String address,
    required Uint8List data,
    bool keepConnected = false,
    required int maxBufferSize,
    required int delayTime,
    ProgressCallback? onProgress,
  }) async {
    final selectedDevices = devices.where(
      (element) => element.address == address,
    );

    if (selectedDevices.isEmpty) {
      throw Exception('Printer Not found, please pair them first');
    }

    final device = selectedDevices.first;

    if (!device.jsDevice.gatt.connected.toDart) {
      throw Exception('Please connect the printer first');
    }

    try {
      final service = await device.jsDevice.gatt
          .getPrimaryService(generalServiceUuid.toJS)
          .toDart;

      final characteristic =
          await service.getCharacteristic(defaultCharUuid.toJS).toDart;

      List<Uint8List> chunks = [];
      final len = data.length;

      // Buffer Size set to static because it's too long for web bluetooth to handle .
      // 384 is currently max bytes tested .
      const bufferSize = 256;
      for (var i = 0; i < len; i += bufferSize) {
        var end = (i + bufferSize < len) ? i + bufferSize : len;
        chunks.add(data.sublist(i, end));
      }

      for (var ix = 0; ix < chunks.length; ix++) {
        await characteristic
            .writeValueWithoutResponse(
              chunks[ix].toJS,
            )
            .toDart;
        if (onProgress != null) {
          onProgress.call(chunks.length, (ix + 1));
          debugPrint('Sent : $ix, Total ${chunks.length}');
        }

        await Future.delayed(
          // Delay using static method because delay from parameter is too long for Web platform to handle
          const Duration(
            milliseconds: 10,
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    } finally {
      if (!keepConnected) {
        disconnect(address);
      }
    }
  }

  /// Connect Device to browser .
  ///
  Future<bool> connect(String address) async {
    final selectedDevices = devices.where(
      (element) => element.address == address,
    );

    if (selectedDevices.isEmpty) {
      throw Exception('Printer Not found, please pair them first');
    }

    final device = selectedDevices.first;

    if (device.jsDevice.gatt.connected.toDart) {
      // Forcing to return true rather than error for supporting some scenarios .
      // throw Exception('Device is already connected');
      return true;
    }

    await device.jsDevice.gatt.connect().toDart;
    // Adding debounce in case something happen .
    //
    await Future.delayed(const Duration(milliseconds: 100));

    return device.jsDevice.gatt.connected.toDart;
  }

  /// Disconnect device from browser .
  ///
  Future<bool> disconnect(String address) async {
    final selectedDevices = devices.where(
      (element) => element.address == address,
    );

    if (selectedDevices.isEmpty) {
      throw Exception('Printer Not found, please pair them first');
    }

    final device = selectedDevices.first;

    if (!device.jsDevice.gatt.connected.toDart) {
      throw Exception('Device is already disconnected');
    }

    device.jsDevice.gatt.disconnect();
    // Adding debounce in case something happen .
    //
    await Future.delayed(const Duration(milliseconds: 100));

    return device.jsDevice.gatt.connected.toDart;
  }

  /// Discover device by calling requestDevice .
  ///
  /// See for supported Browser Here : https://developer.mozilla.org/en-US/docs/Web/API/Bluetooth/requestDevice
  ///
  /// Paired Device will be saved into Internal Website state.
  ///
  /// Improvement for Paired Device by calling getDevices will be implemented near future
  /// if getDevices from Javascript API is stable .
  /// See for getDevices supported browser here :
  ///
  /// https://developer.mozilla.org/en-US/docs/Web/API/Bluetooth/getDevices#browser_compatibility
  Stream<WebBlueoothDartDevice> discover() async* {
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
      bool hasDevice = devices.any(
        (element) => element.address == device!.id.toDart,
      );

      if (!hasDevice) {
        devices.add(
          WebBlueoothDartDevice(
            address: device.id.toDart,
            jsDevice: device,
            name: device.name.toDart,
          ),
        );
      }
    }

    yield* Stream.fromIterable(
      devices,
    );
  }
}
