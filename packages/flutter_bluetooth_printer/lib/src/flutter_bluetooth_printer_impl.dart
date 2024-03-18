part of flutter_bluetooth_printer;

class DiscoveryResult extends DiscoveryState {
  final List<BluetoothDevice> devices;
  DiscoveryResult({required this.devices});
}

enum PaperSize {
  mm58(384, 'Roll Paper 58mm');

  final int width;
  final String name;
  const PaperSize(
    this.width,
    this.name,
  );
}

class FlutterBluetoothPrinter {
  static Stream<DiscoveryState> _discovery() async* {
    final result = <BluetoothDevice>[];
    await for (final state
        in FlutterBluetoothPrinterPlatform.instance.discovery) {
      if (state is BluetoothDevice) {
        result.add(state);
        yield DiscoveryResult(devices: result.toSet().toList());
      } else {
        result.clear();
        yield state;
      }
    }
  }

  static ValueNotifier<BluetoothConnectionState> get connectionStateNotifier =>
      FlutterBluetoothPrinterPlatform.instance.connectionStateNotifier;

  static Stream<DiscoveryState> get discovery => _discovery();

  static Future<void> printBytes({
    required String address,
    required Uint8List data,

    /// if true, you should manually disconnect the printer after finished
    required bool keepConnected,
    int maxBufferSize = 512,
    int delayTime = 120,
    ProgressCallback? onProgress,
  }) async {
    await FlutterBluetoothPrinterPlatform.instance.write(
      address: address,
      data: data,
      onProgress: onProgress,
      keepConnected: keepConnected,
      maxBufferSize: maxBufferSize,
      delayTime: delayTime,
    );
  }

  static Future<void> printImage({
    required String address,
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    PaperSize paperSize = PaperSize.mm58,
    ProgressCallback? onProgress,
    int addFeeds = 0,
    bool useImageRaster = true,
    required bool keepConnected,
    int maxBufferSize = 512,
    int delayTime = 120,
  }) async {
    final generator = Generator();
    final reset = generator.reset();

    final imageData = await generator.encode(
      bytes: imageBytes,
      dotsPerLine: paperSize.width,
      useImageRaster: useImageRaster,
    );

    final additional = <int>[
      for (int i = 0; i < addFeeds; i++) ...Commands.lineFeed,
    ];

    return printBytes(
      keepConnected: keepConnected,
      address: address,
      data: Uint8List.fromList([
        ...reset,
        ...imageData,
        ...reset,
        ...additional,
      ]),
      onProgress: onProgress,
      maxBufferSize: maxBufferSize,
      delayTime: delayTime,
    );
  }

  static Future<BluetoothDevice?> selectDevice(BuildContext context) async {
    final selected = await showModalBottomSheet(
      context: context,
      builder: (context) => const BluetoothDeviceSelector(),
    );
    if (selected is BluetoothDevice) {
      return selected;
    }
    return null;
  }

  static Future<bool> disconnect(String address) async {
    return FlutterBluetoothPrinterPlatform.instance.disconnect(address);
  }
}
