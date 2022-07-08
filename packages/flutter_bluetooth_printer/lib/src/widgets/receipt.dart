part of flutter_bluetooth_printer;

class ReceiptController {
  final ReceiptState state;
  ReceiptController._({
    required this.state,
  });

  Future<void> print({
    required String address,
    PaperSize paperSize = PaperSize.mm58,
    ProgressCallback? onProgress,
  }) {
    return state.print(
      address: address,
      onProgress: onProgress,
      paperSize: paperSize,
    );
  }
}

class Receipt extends StatefulWidget {
  final WidgetBuilder builder;
  final void Function(ReceiptController controller) onInitialized;

  const Receipt({
    Key? key,
    required this.builder,
    required this.onInitialized,
  }) : super(key: key);

  @override
  State<Receipt> createState() => ReceiptState();
}

class ReceiptState extends State<Receipt> {
  final _localKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.onInitialized(ReceiptController._(state: this));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: SingleChildScrollView(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(16.0),
            clipBehavior: Clip.none,
            child: Container(
              width: 384,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: RepaintBoundary(
                key: _localKey,
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                  child: Builder(builder: widget.builder),
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
    PaperSize paperSize = PaperSize.mm58,
    ProgressCallback? onProgress,
  }) async {
    final RenderRepaintBoundary boundary =
        _localKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final im = img.decodePng(bytes)!;
    await FlutterBluetoothPrinter.printImage(
      address: address,
      image: im,
      paperSize: paperSize,
      onProgress: onProgress,
    );
  }
}
