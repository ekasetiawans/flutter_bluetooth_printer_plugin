part of flutter_bluetooth_printer;

class _MethodChannelBluetoothPrinter extends FlutterBluetoothPrinterPlatform {
  final channel = const MethodChannel('maseka.dev/flutter_bluetooth_printer');
  final discoveryChannel =
      const EventChannel('maseka.dev/flutter_bluetooth_printer/discovery');

  ProgressCallback? _progressCallback;

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
      }
      return true;
    });
  }

  @override
  Stream<BluetoothDevice> get discovery => discoveryChannel
          .receiveBroadcastStream(DateTime.now().millisecondsSinceEpoch)
          .map(
        (data) {
          return BluetoothDevice(
            address: data['address'],
            name: data['name'] ?? '',
            type: data['type'] ?? 1,
          );
        },
      );

  @override
  Future<void> write({
    required String address,
    required Uint8List data,
    ProgressCallback? onProgress,
  }) async {
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
  }
}
