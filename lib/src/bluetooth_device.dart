part of bluetooth_printer;

class BluetoothDevice {
  final String name;
  final String address;
  final int type;
  bool _isConnected;
  final BluetoothPrinter _plugin;

  BluetoothDevice._internal({
    required this.name,
    required this.address,
    required this.type,
    required bool isConnected,
    required BluetoothPrinter printer,
  })  : _plugin = printer,
        _isConnected = isConnected;

  Future<bool> connect() async {
    _isConnected = await _plugin._connect(this);
    return _isConnected;
  }

  bool get isConnected => _isConnected;
  Future<void> disconnect() async {
    return _plugin._channel.invokeMethod('disconnect');
  }

  Future<void> printBytes({
    required Uint8List bytes,
    void Function(int total, int progress)? progress,
  }) async {
    final completer = Completer<bool>();
    StreamSubscription? listener;
    listener = _plugin._printingProgress.stream.listen((event) {
      final int t = event['total'];
      final int p = event['progress'];
      if (progress != null) {
        progress(t, p);
      }

      if (t == p) {
        listener?.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    await _plugin._channel.invokeMethod(
      'print',
      bytes,
    );

    await completer.future;
  }

  Future<void> printImage({
    required img.Image image,
    PaperSize paperSize = PaperSize.mm58,
    void Function(int total, int progress)? progress,
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

    await printBytes(
      bytes: Uint8List.fromList(data),
      progress: progress,
    );
  }

  Future<void> printPdf({
    required Uint8List data,
    int pageNumber = 1,
    PaperSize paperSize = PaperSize.mm58,
    void Function(int total, int progress)? progress,
  }) async {
    final bytes = await _rasterPdf(
      data: data,
      pageNumber: pageNumber,
      width: paperSize.width,
    );

    final image = img.decodeJpg(bytes);
    if (image != null) {
      return printImage(
        image: image,
        paperSize: paperSize,
        progress: progress,
      );
    }

    throw Exception('Invalid JPG Image');
  }

  Future<List<int>> _rasterPdf({
    required Uint8List data,
    required int pageNumber,
    required int width,
  }) async {
    final doc = await rd.PdfDocument.openData(Uint8List.fromList(data));
    final page = await doc.getPage(pageNumber);

    double ratio = width / page.width;
    int height = (page.height * ratio).ceil();

    final pageImage = await page.render(
      width: width,
      height: height,
      format: rd.PdfPageFormat.JPEG,
    );

    return pageImage!.bytes;
  }
}
