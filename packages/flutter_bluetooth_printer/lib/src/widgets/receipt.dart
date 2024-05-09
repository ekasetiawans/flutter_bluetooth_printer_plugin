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

  Future<bool> print({
    required String address,
    ProgressCallback? onProgress,

    /// add lines after print
    int addFeeds = 0,
    bool keepConnected = false,
    int maxBufferSize = 512,
    int delayTime = 120,
  }) {
    return _state.print(
      address: address,
      onProgress: onProgress,
      addFeeds: addFeeds,
      keepConnected: keepConnected,
      maxBufferSize: maxBufferSize,
      delayTime: delayTime,
    );
  }
}

class Receipt extends StatefulWidget {
  final WidgetBuilder builder;
  final Widget Function(BuildContext context, Widget child)? containerBuilder;
  final Color backgroundColor;
  final TextStyle? defaultTextStyle;
  final void Function(ReceiptController controller) onInitialized;

  const Receipt({
    Key? key,
    this.defaultTextStyle,
    this.backgroundColor = Colors.grey,
    required this.builder,
    required this.onInitialized,
    this.containerBuilder,
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
    const style = TextStyle(
      fontSize: 24,
      height: 1.0,
      color: Colors.black,
      fontFeatures: [
        FontFeature.slashedZero(),
      ],
    );

    var receipt = RepaintBoundary(
      key: _localKey,
      child: Container(
        color: Colors.white,
        child: DefaultTextStyle.merge(
          style: style.merge(
            widget.defaultTextStyle ??
                const TextStyle(
                  fontFamily: 'Receipt',
                  package: 'flutter_bluetooth_printer',
                ),
          ),
          child: SizedBox(
            width: _paperSize.width.toDouble(),
            child: Builder(builder: widget.builder),
          ),
        ),
      ),
    );

    if (widget.containerBuilder != null) {
      return widget.containerBuilder!(context, receipt);
    }

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
                  child: receipt,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> print({
    required String address,
    ProgressCallback? onProgress,
    int addFeeds = 0,
    bool keepConnected = false,
    int maxBufferSize = 512,
    int delayTime = 120,
  }) async {
    final RenderRepaintBoundary boundary =
        _localKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final screenWidth = boundary.size.width;
    double quality = _paperSize.width / screenWidth;

    final image = await boundary.toImage(pixelRatio: quality);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    var bytes = byteData!.buffer.asUint8List();

    return FlutterBluetoothPrinter.printImageSingle(
      address: address,
      imageBytes: bytes,
      imageWidth: image.width,
      imageHeight: image.height,
      paperSize: _paperSize,
      onProgress: onProgress,
      addFeeds: addFeeds,
      keepConnected: keepConnected,
      maxBufferSize: bytes.length,
      delayTime: delayTime,
    );
  }
}

class _ImagePreviewForDebug extends StatelessWidget {
  final Uint8List bytes;
  const _ImagePreviewForDebug({
    super.key,
    required this.bytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Preview'),
      ),
      body: Image.memory(bytes),
    );
  }
}
