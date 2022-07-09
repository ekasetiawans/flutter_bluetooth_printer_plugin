part of flutter_bluetooth_printer;

class FlutterBluetoothPrinter {
  static void registerWith() {
    FlutterBluetoothPrinterPlatform.instance = _MethodChannelBluetoothPrinter();
  }

  static Stream<List<BluetoothDevice>> _discovery() async* {
    final result = <BluetoothDevice>[];
    await for (final device
        in FlutterBluetoothPrinterPlatform.instance.discovery) {
      result.add(device);
      yield result;
    }
  }

  static ValueNotifier<BluetoothConnectionState> get connectionStateNotifier =>
      FlutterBluetoothPrinterPlatform.instance.connectionStateNotifier;

  static Stream<List<BluetoothDevice>> get discovery => _discovery();

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

  static Future<void> printPdf({
    required String address,
    required Uint8List data,
    int pageNumber = 1,
    PaperSize paperSize = PaperSize.mm58,
    ProgressCallback? onProgress,
  }) async {
    final bytes = await _rasterPdf(
      data: data,
      pageNumber: pageNumber,
      width: paperSize.width,
    );

    final image = img.decodeJpg(bytes);
    if (image != null) {
      return printImage(
        address: address,
        image: image,
        paperSize: paperSize,
        onProgress: onProgress,
      );
    }

    throw Exception('Invalid JPG Image');
  }

  static Future<List<int>> _rasterPdf({
    required Uint8List data,
    required int pageNumber,
    required int width,
  }) async {
    final doc = await rd.PdfDocument.openData(Uint8List.fromList(data));
    final page = await doc.getPage(pageNumber);

    double ratio = width / page.width;
    int height = (page.height * ratio).ceil();

    final pageImage = await page.render(
      width: width.toDouble(),
      height: height.toDouble(),
      format: rd.PdfPageImageFormat.jpeg,
    );

    return pageImage!.bytes;
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
