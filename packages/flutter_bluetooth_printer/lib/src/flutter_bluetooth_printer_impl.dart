part of flutter_bluetooth_printer;

class DiscoveryResult extends DiscoveryState {
  final List<BluetoothDevice> devices;
  DiscoveryResult({required this.devices});
}

class FlutterBluetoothPrinter {
  static void registerWith() {
    FlutterBluetoothPrinterPlatform.instance = _MethodChannelBluetoothPrinter();
  }

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
    ProgressCallback? onProgress,
  }) async {
    await FlutterBluetoothPrinterPlatform.instance.write(
      address: address,
      data: data,
      onProgress: onProgress,
    );
  }

  static Future<void> printImage({
    required String address,
    required img.Image image,
    PaperSize paperSize = PaperSize.mm58,
    ProgressCallback? onProgress,
  }) async {
    img.Image src;

    final dotsPerLine = paperSize.width;

    // make sure image not bigger than printable area
    if (image.width > dotsPerLine) {
      double ratio = dotsPerLine / image.width;
      int height = (image.height * ratio).ceil();
      src = img.copyResize(
        image,
        width: dotsPerLine,
        height: height,
      );
    } else {
      src = image;
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final data = generator.image(src);

    return printBytes(
      address: address,
      data: Uint8List.fromList(data),
      onProgress: onProgress,
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
}
