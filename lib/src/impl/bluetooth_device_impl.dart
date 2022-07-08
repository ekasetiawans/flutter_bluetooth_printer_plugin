part of flutter_bluetooth_printer;

class _BluetoothDeviceImpl extends BluetoothDevice {
  final MethodChannel _channel =
      const MethodChannel('maseka.dev/bluetooth_printer');
  late final MethodChannel _deviceChannel;

  bool _isConnected;

  _BluetoothDeviceImpl({
    String? name,
    required String address,
    required int type,
    required bool isConnected,
  })  : _isConnected = isConnected,
        super(
          name: name,
          address: address,
          type: type,
        ) {
    _deviceChannel = MethodChannel(
      'maseka.dev/bluetooth_printer/$address',
    );
    _deviceChannel.setMethodCallHandler(_onCall);
  }

  void Function(int total, int progress)? _onProgress;
  Future<dynamic> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'onConnected':
        _isConnected = call.arguments as bool;
        break;

      case 'onDisconnected':
        _isConnected = call.arguments as bool;
        break;

      case 'onPrintingProgress':
        final int total = call.arguments['total'];
        final int progress = call.arguments['progress'];
        _onProgress?.call(total, progress);
        break;

      case 'error':
        throw call.arguments as Exception;
    }
  }

  @override
  Future<bool> connect() async {
    _isConnected = await _channel.invokeMethod('connect', address);
    return _isConnected;
  }

  @override
  bool get isConnected => _isConnected;
  @override
  Future<bool> disconnect() async {
    final result = await _deviceChannel.invokeMethod('disconnect');
    if (result) {
      _isConnected = false;
    }

    return result;
  }

  @override
  Future<void> printBytes({
    required Uint8List bytes,
    void Function(int total, int progress)? progress,
  }) async {
    if (!_isConnected) {
      throw Exception('Device is not connected');
    }

    final completer = Completer<bool>();
    StreamSubscription? listener;
    _onProgress = ((t, p) {
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

    await _deviceChannel.invokeMethod(
      'write',
      bytes,
    );

    await completer.future;
  }

  @override
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

  @override
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
      width: width.toDouble(),
      height: height.toDouble(),
      format: rd.PdfPageImageFormat.jpeg,
    );

    return pageImage!.bytes;
  }
}
