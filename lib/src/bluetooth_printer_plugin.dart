part of bluetooth_printer;

class BluetoothPrinter {
  final _channel = const MethodChannel('id.flutter.plugins/bluetooth_printer');
  final _discoverController =
      StreamController<List<BluetoothDevice>>.broadcast();

  final _stateController = StreamController<int>.broadcast();

  final _printingProgress = StreamController<Map<String, dynamic>>.broadcast();

  Stream<List<BluetoothDevice>> get scanResults => _discoverController.stream;
  Stream<int> get stateChanged => _stateController.stream;

  final List<BluetoothDevice> _devices = [];
  BluetoothPrinter() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDiscovered':
          final dev = call.arguments;
          final device = BluetoothDevice._internal(
            name: dev['name'],
            address: dev['address'],
            type: dev['type'],
            isConnected: dev['is_connected'],
            printer: this,
          );

          if (!_devices.any((element) => element.address == device.address)) {
            _devices.add(device);
            _discoverController.sink.add(_devices);
          }
          break;

        case 'onStateChanged':
          int id = call.arguments['id'];
          _stateController.sink.add(id);
          break;

        case 'onPrintingProgress':
          int total = call.arguments['total'];
          int progress = call.arguments['progress'];
          _printingProgress.sink.add({
            'total': total,
            'progress': progress,
          });
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
    _discoverController.sink.add(_devices);
    await _channel.invokeMethod('startScan');
  }

  Future<BluetoothDevice?> getDeviceByAddress({required String address}) async {
    final idx = _devices.indexWhere((element) => element.address == address);
    if (idx >= 0) {
      return _devices[idx];
    }

    final dev = await _channel.invokeMethod('getDevice', {
      'address': address,
    });

    if (dev != null) {
      return BluetoothDevice._internal(
        name: dev['name'],
        address: dev['address'],
        type: dev['type'],
        isConnected: dev['is_connected'],
        printer: this,
      );
    }
  }

  Future<BluetoothDevice?> getConnectedDevice() async {
    final res = await _channel.invokeMethod('connectedDevice');
    if (res != null) {
      final device = BluetoothDevice._internal(
        name: res['name'],
        address: res['address'],
        type: res['type'],
        isConnected: res['is_connected'],
        printer: this,
      );
      return device;
    }

    return null;
  }

  Future<bool> _connect(BluetoothDevice device) async {
    final completer = Completer<bool>();
    final subscriber = stateChanged.listen((event) {
      if (event == 1) {
        completer.complete(true);
        return;
      }

      if (event == 4 || event == 2) {
        completer.complete(false);
        return;
      }
    });

    try {
      await _channel.invokeMethod('connect', {
        'address': device.address,
      });

      final res = await completer.future;
      return res;
    } catch (e) {
      return false;
    } finally {
      subscriber.cancel();
    }
  }

  Future<void> stopScan() async {
    await _channel.invokeMethod('stopScan');
  }

  Future<void> _cleanUp() async {
    _discoverController.close();
    _printingProgress.close();
    _stateController.close();
    await stopScan();
  }

  void dispose() {
    _cleanUp();
  }
}
