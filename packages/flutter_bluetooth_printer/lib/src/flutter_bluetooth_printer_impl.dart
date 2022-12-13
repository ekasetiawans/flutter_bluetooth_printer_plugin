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
    int addFeeds = 0,
    bool useImageRaster = false,
  }) async {
    img.Image src;
    image = img.pixelate(
      image,
      (image.width / paperSize.width).round(),
      mode: img.PixelateMode.average,
    );

    image = _blackwhite(image);

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
    final generator = Generator(
      paperSize,
      profile,
      spaceBetweenRows: 0,
    );
    List<int> imageData;
    if (useImageRaster) {
      imageData = generator.imageRaster(
        src,
        highDensityHorizontal: true,
        highDensityVertical: true,
        imageFn: PosImageFn.bitImageRaster,
      );
    } else {
      imageData = generator.image(src);
    }

    final additional = [
      ...generator.emptyLines(addFeeds),
      ...generator.text('.'),
    ];

    return printBytes(
      address: address,
      data: Uint8List.fromList([
        ...generator.reset(),
        ...imageData,
        ...generator.reset(),
        ...additional,
      ]),
      onProgress: onProgress,
    );
  }

  static img.Image _blackwhite(img.Image src) {
    final w = src.width;
    final h = src.height;

    final res = img.Image(w, h);
    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        final idx = y * w + x;

        final pixel = src[idx];
        final r = img.getRed(pixel);
        final b = img.getBlue(pixel);
        final g = img.getGreen(pixel);

        int c;
        final l = img.getLuminanceRgb(r, g, b) / 255;
        if (l > 0.8) {
          c = img.getColor(255, 255, 255);
        } else {
          c = img.getColor(0, 0, 0);
        }

        final u = BigInt.from(c).toUnsigned(32);
        res[idx] = u.toInt();
      }
    }

    return res;
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
