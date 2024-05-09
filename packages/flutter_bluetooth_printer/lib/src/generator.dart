part of flutter_bluetooth_printer;

class Generator {
  List<int> reset() {
    List<int> bytes = [];
    bytes += cInit.codeUnits;
    return bytes;
  }

  List<int> _intLowHigh(int value, int bytesNb) {
    final dynamic maxInput = 256 << (bytesNb * 8) - 1;

    if (bytesNb < 1 || bytesNb > 4) {
      throw Exception('Can only output 1-4 bytes');
    }
    if (value < 0 || value > maxInput) {
      throw Exception(
          'Number is too large. Can only output up to $maxInput in $bytesNb bytes');
    }

    final List<int> res = <int>[];
    int buf = value;
    for (int i = 0; i < bytesNb; ++i) {
      res.add(buf % 256);
      buf = buf ~/ 256;
    }
    return res;
  }

  List<int> _imageRaster(img.Image image) {
    final int widthPx = image.width;
    final int heightPx = image.height;
    final int widthBytes = (widthPx + 7) ~/ 8;
    final List<int> resterizedData = _toRasterFormat(image);
    const int densityByte = 0;
    final List<int> header = <int>[
      ...cRasterImg2.codeUnits,
    ];
    header.add(densityByte);
    header.addAll(_intLowHigh(widthBytes, 2)); // xL xH
    header.addAll(_intLowHigh(heightPx, 2)); // yL yH

    return <int>[
      ...header,
      ...resterizedData,
    ];
  }

  Future<List<int>> rasterImage({
    required Uint8List bytes,
    required int dotsPerLine,
  }) async {
    // need to convert to JPG
    // iOS issue, when using PNG the output is broken

    final newBytes = img.encodeJpg(img.decodePng(bytes)!);
    img.Image src = img.decodeJpg(newBytes)!;
    src = img.copyResize(
      src,
      width: dotsPerLine,
      maintainAspect: true,
      backgroundColor: img.ColorRgba8(255, 255, 255, 255),
      interpolation: img.Interpolation.cubic,
    );
    src = img.grayscale(src);

    final int widthPx = src.width;
    final int widthBytes = widthPx ~/ 8;
    final int heightPx = src.height;

    final list = _toRasterFormat(src);

    const int densityByte = 0;
    final List<int> header = <int>[
      ...cRasterImg2.codeUnits,
    ];
    header.add(densityByte);
    header.addAll(_intLowHigh(widthBytes, 2)); // xL xH
    header.addAll(_intLowHigh(heightPx, 2));

    return <int>[
      ...header,
      ...list,
    ];
  }

  List<int> _graphic(img.Image image) {
    final int widthPx = image.width;
    final int heightPx = image.height;
    final int widthBytes = (widthPx + 7) ~/ 8;
    final List<int> resterizedData = _toRasterFormat(image);
    // 'GS ( L' - FN_112 (Image data)
    final List<int> header1 = List.from(cRasterImg.codeUnits);
    header1.addAll(_intLowHigh(widthBytes * heightPx + 10, 2)); // pL pH
    header1.addAll([48, 112, 48]); // m=48, fn=112, a=48
    header1.addAll([1, 1]); // bx=1, by=1
    header1.addAll([49]); // c=49
    header1.addAll(_intLowHigh(widthBytes, 2)); // xL xH
    header1.addAll(_intLowHigh(heightPx, 2)); // yL yH

    // 'GS ( L' - FN_50 (Run print)
    final List<int> header2 = List.from("\x1D(L".codeUnits);
    header2.addAll([2, 0]); // pL pH
    header2.addAll([48, 50]); // m fn[2,50]

    return <int>[
      ...header1,
      ...resterizedData,
      ...header2,
    ];
  }

  /// Image rasterization
  List<int> _toRasterFormat(img.Image imgSrc) {
    final img.Image image = img.Image.from(imgSrc); // make a copy
    final int widthPx = image.width;
    final int heightPx = image.height;

    img.grayscale(image);
    img.invert(image);

    // R/G/B channels are same -> keep only one channel
    final List<int> oneChannelBytes = [];
    final List<int> buffer = image.getBytes(order: img.ChannelOrder.rgba);
    for (int i = 0; i < buffer.length; i += 4) {
      oneChannelBytes.add(buffer[i]);
    }

    // Add some empty pixels at the end of each line (to make the width divisible by 8)
    if (widthPx % 8 != 0) {
      final targetWidth = (widthPx + 8) - (widthPx % 8);
      final missingPx = targetWidth - widthPx;
      final extra = Uint8List(missingPx);
      for (int i = 0; i < heightPx; i++) {
        final pos = (i * widthPx + widthPx) + i * missingPx;
        oneChannelBytes.insertAll(pos, extra);
      }
    }

    // Pack bits into bytes
    return _packBitsIntoBytes(oneChannelBytes);
  }

  /// Merges each 8 values (bits) into one byte
  List<int> _packBitsIntoBytes(List<int> bytes) {
    const pxPerLine = 8;
    final List<int> res = <int>[];
    const threshold = 256 * 0.5; // set the greyscale -> b/w threshold here
    for (int i = 0; i < bytes.length; i += pxPerLine) {
      int newVal = 0;
      for (int j = 0; j < pxPerLine; j++) {
        newVal = _transformUint32Bool(
          newVal,
          pxPerLine - j,
          bytes[i + j] > threshold,
        );
      }
      res.add(newVal ~/ 2);
    }
    return res;
  }

  /// Replaces a single bit in a 32-bit unsigned integer.
  int _transformUint32Bool(int uint32, int shift, bool newValue) {
    return ((0xFFFFFFFF ^ (0x1 << shift)) & uint32) |
        ((newValue ? 1 : 0) << shift);
  }

  Future<img.Image> optimizeImage({
    required Uint8List bytes,
    required int dotsPerLine,
  }) async {
    img.Image src = img.decodeJpg(bytes)!;
    src = img.grayscale(src);

    final w = src.width;
    final h = src.height;

    final res = img.Image(width: w, height: h);
    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        final pixel = src.getPixelSafe(x, y);
        final lum = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);

        img.Color c;
        final l = lum / 255;
        if (l > 0.8) {
          c = img.ColorUint8.rgb(255, 255, 255);
        } else {
          c = img.ColorUint8.rgb(0, 0, 0);
        }

        res.setPixel(x, y, c);
      }
    }

    src = res;
    src = img.copyResize(
      src,
      width: dotsPerLine,
      maintainAspect: true,
    );

    return src;
  }

  Future<List<int>> _encodeImage(Map<String, dynamic> arg) async {
    final dotsPerLine = arg['dotsPerLine'];
    final pngBytes = arg['bytes'];
    final useImageRaster = arg['useImageRaster'];

    final image = await optimizeImage(
      dotsPerLine: dotsPerLine,
      bytes: pngBytes,
    );

    if (useImageRaster) {
      return _imageRaster(image);
    }

    return _image(image);
  }

  Future<List<int>> _encodeX(Map<String, dynamic> arg) async {
    final dotsPerLine = arg['dotsPerLine'];
    final pngBytes = arg['bytes'];

    return rasterImage(
      bytes: pngBytes,
      dotsPerLine: dotsPerLine,
    );
  }

  Future<List<int>> encode({
    required Uint8List bytes,
    required int dotsPerLine,
    required bool useImageRaster,
  }) {
    final arg = {
      'bytes': bytes,
      'dotsPerLine': dotsPerLine,
      'useImageRaster': useImageRaster,
    };

    return compute(_encodeX, arg);
  }

  List<int> _image(
    img.Image imgSrc, {
    bool highDensityHorizontal = true,
    bool highDensityVertical = true,
  }) {
    List<int> bytes = [];

    final img.Image image = img.Image.from(imgSrc); // make a copy
    img.invert(image);
    // flip(image, Flip.horizontal);
    img.flip(image, direction: img.FlipDirection.horizontal);
    // final Image imageRotated = copyRotate(image, 270);
    final img.Image imageRotated = img.copyRotate(
      image,
      angle: 270,
      interpolation: img.Interpolation.nearest,
    );

    final int lineHeight = highDensityVertical ? 3 : 1;

    /// const int lineHeight = 3;
    final List<List<int>> blobs = _toColumnFormat(imageRotated, lineHeight * 8);

    // Compress according to line density
    // Line height contains 8 or 24 pixels of src image
    // Each blobs[i] contains greyscale bytes [0-255]
    // const int pxPerLine = 24 ~/ lineHeight;
    for (int blobInd = 0; blobInd < blobs.length; blobInd++) {
      blobs[blobInd] = _packBitsIntoBytes(blobs[blobInd]);
    }

    final int heightPx = imageRotated.height;
    final int densityByte =
        (highDensityHorizontal ? 1 : 0) + (highDensityVertical ? 32 : 0);

    final List<int> header = List.from(cBitImg.codeUnits);
    header.add(densityByte);
    header.addAll(_intLowHigh(heightPx, 2));

    // Image alignment
    bytes += latin1.encode(cAlignCenter);

    // Adjust line spacing (for 16-unit line feeds): ESC 3 0x10 (HEX: 0x1b 0x33 0x10)
    bytes += [27, 51, 16];
    for (int i = 0; i < blobs.length; ++i) {
      bytes += List.from(header)
        ..addAll(blobs[i])
        ..addAll('\n'.codeUnits);
    }
    // Reset line spacing: ESC 2 (HEX: 0x1b 0x32)
    bytes += [27, 50];
    return bytes;
  }

  /// Extract slices of an image as equal-sized blobs of column-format data.
  ///
  /// [image] Image to extract from
  /// [lineHeight] Printed line height in dots
  List<List<int>> _toColumnFormat(img.Image imgSrc, int lineHeight) {
    final img.Image image = img.Image.from(imgSrc); // make a copy

    // Determine new width: closest integer that is divisible by lineHeight
    final int widthPx = (image.width + lineHeight) - (image.width % lineHeight);
    final int heightPx = image.height;

    /// Create a black bottom layer
    final biggerImage = copyResize(image, width: widthPx, height: heightPx);

    // fill(biggerImage, 0)
    fill(biggerImage, color: ColorFloat16(0));

    /// Insert source image into bigger one
    // drawImage(biggerImage, image, dstX: 0, dstY: 0);
    compositeImage(biggerImage, image, dstX: 0, dstY: 0);

    int left = 0;
    final List<List<int>> blobs = [];

    while (left < widthPx) {
      // final Image slice = copyCrop(biggerImage, left, 0, lineHeight, heightPx);
      final img.Image slice = copyCrop(biggerImage,
          x: left, y: 0, width: lineHeight, height: heightPx);
      // final Uint8List bytes = slice.getBytes(  format: Format.luminance);
      final Uint8List bytes = slice.getBytes(order: ChannelOrder.bgr);
      blobs.add(bytes);
      left += lineHeight;
    }

    return blobs;
  }
}
