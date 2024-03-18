part of flutter_bluetooth_printer;

class ReceiptController with ChangeNotifier {
  final ReceiptState _state;

  PaperSize _paperSize = PaperSize.mm58;
  PaperSize get paperSize => _paperSize;
  set paperSize(PaperSize size) {
    _paperSize = size;
    notifyListeners();
  }

  ReceiptController._({
    required ReceiptState state,
  }) : _state = state;

  Future<void> print({
    required String address,
    ProgressCallback? onProgress,

    /// add lines after print
    int addFeeds = 0,
    bool useImageRaster = true,
    bool keepConnected = false,
  }) {
    return _state.print(
      address: address,
      onProgress: onProgress,
      addFeeds: addFeeds,
      useImageRaster: useImageRaster,
      keepConnected: keepConnected,
    );
  }
}

class Receipt extends StatefulWidget {
  final WidgetBuilder builder;
  final Color backgroundColor;
  final TextStyle? defaultTextStyle;
  final void Function(ReceiptController controller) onInitialized;

  const Receipt({
    Key? key,
    this.defaultTextStyle,
    this.backgroundColor = Colors.grey,
    required this.builder,
    required this.onInitialized,
  }) : super(key: key);

  @override
  State<Receipt> createState() => ReceiptState();
}

class ReceiptState extends State<Receipt> {
  final _localKey = GlobalKey();
  PaperSize _paperSize = PaperSize.mm58;
  late ReceiptController controller;

  @override
  void initState() {
    super.initState();
    controller = ReceiptController._(state: this);
    controller.addListener(_listener);
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.onInitialized(controller);
    });
  }

  void _listener() {
    if (controller._paperSize != _paperSize) {
      if (mounted) {
        setState(() {
          _paperSize = controller._paperSize;
        });
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: ClipRect(
        clipBehavior: Clip.hardEdge,
        child: Container(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            child: InteractiveViewer(
              boundaryMargin: EdgeInsets.zero,
              clipBehavior: Clip.none,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: RepaintBoundary(
                    key: _localKey,
                    child: Container(
                      color: Colors.white,
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.0,
                          color: Colors.black,
                          fontFamily: 'Receipt',
                          package: 'flutter_bluetooth_printer',
                          fontFeatures: [
                            FontFeature.slashedZero(),
                          ],
                        ).merge(widget.defaultTextStyle),
                        child: SizedBox(
                          width: _paperSize.width.toDouble(),
                          child: Builder(builder: widget.builder),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> print({
    required String address,
    ProgressCallback? onProgress,
    int addFeeds = 0,
    bool useImageRaster = true,
    bool keepConnected = false,
    int maxBufferSize = 512,
    int delayTime = 120,
  }) async {
    int quality = 1;
    final RenderRepaintBoundary boundary =
        _localKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: quality.toDouble());
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    var src = img.decodePng(bytes)!;

    await FlutterBluetoothPrinter.printImage(
      address: address,
      imageBytes: img.encodeJpg(src),
      imageWidth: image.width,
      imageHeight: image.height,
      paperSize: _paperSize,
      onProgress: onProgress,
      addFeeds: addFeeds,
      useImageRaster: useImageRaster,
      keepConnected: keepConnected,
      maxBufferSize: maxBufferSize,
      delayTime: delayTime,
    );
  }
}
