part of flutter_bluetooth_printer;

extension PaperSizeName on PaperSize {
  String get name {
    if (this == PaperSize.mm58) {
      return '58mm';
    } else if (this == PaperSize.mm72) {
      return '72mm';
    } else if (this == PaperSize.mm80) {
      return '80mm';
    }

    return 'Unknown';
  }
}

class ReceiptController {
  final ReceiptState state;
  ReceiptController._({
    required this.state,
  });

  Future<void> print({
    required String address,
    ProgressCallback? onProgress,

    /// add lines after print
    int linesAfter = 0,
  }) {
    return state.print(
      address: address,
      onProgress: onProgress,
      addFeeds: linesAfter,
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
  PaperSize _paperSize = PaperSize.mm58;

  @override
  void initState() {
    super.initState();
    widget.onInitialized(ReceiptController._(state: this));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Paper Size:'),
              trailing: PopupMenuButton<PaperSize>(
                initialValue: _paperSize,
                onSelected: (value) {
                  setState(() {
                    _paperSize = value;
                  });
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: PaperSize.mm58,
                    child: Text('58mm'),
                  ),
                  PopupMenuItem(
                    value: PaperSize.mm72,
                    child: Text('72mm'),
                  ),
                  PopupMenuItem(
                    value: PaperSize.mm80,
                    child: Text('80mm'),
                  ),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_paperSize.name),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
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
                                height: 1.1,
                                color: Colors.black,
                                fontFamily: 'HermeneusOne',
                                package: 'flutter_bluetooth_printer',
                              ),
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
          ),
        ],
      ),
    );
  }

  Future<void> print({
    required String address,
    ProgressCallback? onProgress,
    int addFeeds = 0,
  }) async {
    int quality = 4;
    final RenderRepaintBoundary boundary =
        _localKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: quality.toDouble());
    final byteData = await image.toByteData(format: ImageByteFormat.rawRgba);
    final bytes = byteData!.buffer.asUint8List();

    final im = img.Image.fromBytes(image.width, image.height, bytes);

    await FlutterBluetoothPrinter.printImage(
      address: address,
      image: im,
      paperSize: _paperSize,
      onProgress: onProgress,
      addFeeds: addFeeds,
    );
  }
}
