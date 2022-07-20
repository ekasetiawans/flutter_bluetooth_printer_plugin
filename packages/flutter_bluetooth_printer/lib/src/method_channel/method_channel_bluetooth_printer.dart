part of flutter_bluetooth_printer;

class _MethodChannelBluetoothPrinter extends FlutterBluetoothPrinterPlatform {
  final channel = const MethodChannel('maseka.dev/flutter_bluetooth_printer');
  final discoveryChannel =
      const EventChannel('maseka.dev/flutter_bluetooth_printer/discovery');

  ProgressCallback? _progressCallback;
  final StreamController<BluetoothState> _stateController =
      StreamController.broadcast();

  bool _isInitialized = false;
  void _init() {
    if (_isInitialized) return;
    _isInitialized = true;
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'didUpdateState':
          final index = call.arguments as int;
          connectionStateNotifier.value =
              BluetoothConnectionState.values[index];
          break;

        case 'onPrintingProgress':
          final total = call.arguments['total'] as int;
          final progress = call.arguments['progress'] as int;
          _progressCallback?.call(total, progress);
          break;

        case 'onBluetoothStateChanged':
          final value = call.arguments as int;
          _stateController.sink.add(_intToState(value));
          break;
      }
      return true;
    });
  }

  BluetoothState _intToState(int value) {
    switch (value) {
      case 0:
        return BluetoothState.unknown;

      case 1:
        return BluetoothState.disabled;

      case 2:
        return BluetoothState.enabled;

      case 3:
        return BluetoothState.notPermitted;

      case 4:
        return BluetoothState.permitted;
    }

    return BluetoothState.unknown;
  }

  @override
  Stream<BluetoothDevice> get discovery => discoveryChannel
          .receiveBroadcastStream(DateTime.now().millisecondsSinceEpoch)
          .map(
        (data) {
          return BluetoothDevice(
            address: data['address'],
            name: data['name'],
            type: data['type'],
          );
        },
      );

  bool _isBusy = false;

  @override
  Future<void> write({
    required String address,
    required Uint8List data,
    ProgressCallback? onProgress,
  }) async {
    try {
      if (_isBusy) {
        throw busyDeviceException;
      }

      _isBusy = true;
      _init();

      // ensure device is available
      await discovery
          .firstWhere((element) => element.address == address)
          .timeout(const Duration(seconds: 10));

      _progressCallback = onProgress;

      await channel.invokeMethod('write', {
        'address': address,
        'data': data,
      });

      _progressCallback = null;
    } finally {
      _isBusy = false;
    }
  }

  @override
  Stream<BluetoothState> get stateStream => _stateStream();

  Stream<BluetoothState> _stateStream() async* {
    _init();
    final result = await channel.invokeMethod('getState');
    yield _intToState(result);
    yield* _stateController.stream;
  }
}
