part of flutter_bluetooth_printer;

class DiscoveryResult extends DiscoveryState {
  final List<BluetoothDevice> devices;
  DiscoveryResult({required this.devices});
}

enum PaperSize {
  // original is 384 => 48 * 8
  mm58(360, 'Roll Paper 58mm');

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

  static Future<bool> printBytes({
    required String address,
    required Uint8List data,

    /// if true, you should manually disconnect the printer after finished
    required bool keepConnected,
    int maxBufferSize = 512,
    int delayTime = 120,
    ProgressCallback? onProgress,
  }) {
    return FlutterBluetoothPrinterPlatform.instance.write(
      address: address,
      data: data,
      onProgress: onProgress,
      keepConnected: keepConnected,
      maxBufferSize: maxBufferSize,
      delayTime: delayTime,
    );
  }

  static Future<bool> printImageSingle({
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
    try {
      final generator = Generator();
      final reset = generator.reset();

      final isConnected = await connect(address);
      if (!isConnected) {
        return false;
      }

      await printBytes(
        address: address,
        data: Uint8List.fromList(reset),
        keepConnected: true,
      );

      final res = await Future.wait([
        generator.encode(
          bytes: imageBytes,
          dotsPerLine: paperSize.width,
          useImageRaster: useImageRaster,
        ),
        // wait for printer buffer cleared by ESC @
        Future.delayed(const Duration(milliseconds: 200)),
      ]);

      final imageData = res[0];
      final additional = <int>[
        for (int i = 0; i < addFeeds; i++) ...Commands.lineFeed,
      ];

      await printBytes(
        keepConnected: true,
        address: address,
        data: Uint8List.fromList([
          ...imageData,
          ...reset,
          ...additional,
        ]),
        onProgress: onProgress,
        maxBufferSize: maxBufferSize,
        delayTime: delayTime,
      );

      if (!keepConnected) {
        await disconnect(address);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> printImageChunks({
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
    var src = img.decodeJpg(imageBytes);
    if (src == null) {
      return false;
    }

    src = img.grayscale(src);
    src = img.copyResize(
      src,
      width: paperSize.width,
      maintainAspect: true,
      interpolation: img.Interpolation.cubic,
    );

    final totalHeight = src.height;
    final lineHeight = paperSize.width;

    final generator = Generator();
    final reset = generator.reset();

    final chunks = (totalHeight.toDouble() / lineHeight.toDouble()).ceil();
    for (int i = 0; i < chunks; i++) {
      final croppedImg = img.copyCrop(
        src,
        x: 0,
        y: i * lineHeight,
        width: src.width,
        height: math.min(lineHeight, totalHeight - i * 8),
      );

      final imageData = await generator.rasterImage(
        bytes: img.encodeJpg(croppedImg),
        dotsPerLine: paperSize.width,
      );

      final result = await printBytes(
        keepConnected: true,
        address: address,
        data: Uint8List.fromList([
          ...reset,
          ...imageData,
        ]),
        maxBufferSize: 4096,
        delayTime: 0,
      );

      if (!result) {
        return false;
      }
    }

    final additional = <int>[
      for (int i = 0; i < addFeeds; i++) ...Commands.lineFeed,
    ];

    return printBytes(
      keepConnected: keepConnected,
      address: address,
      data: Uint8List.fromList([
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

  static Future<bool> connect(String address) async {
    return FlutterBluetoothPrinterPlatform.instance.connect(address);
  }

  static Future<BluetoothState> getState() async {
    return FlutterBluetoothPrinterPlatform.instance.checkState();
  }
}
