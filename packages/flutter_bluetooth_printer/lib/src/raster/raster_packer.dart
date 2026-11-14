import 'dart:typed_data';

class RasterPacker {
  const RasterPacker._();
  static const int defaultThreshold = 128;
  static int bytesPerRow(int widthPx) => (widthPx + 7) >> 3;

  static Uint8List pack({
    required Uint8List rgba,
    required int width,
    required int height,
    bool premultipliedAlpha = false,
    int threshold = defaultThreshold,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Invalid image size: ${width}x$height');
    }
    if (rgba.length < width * height * 4) {
      throw ArgumentError.value(
        rgba.length,
        'rgba',
        'Data length is less than ${width * height * 4} byte',
      );
    }

    final widthBytes = bytesPerRow(width);
    final output = Uint8List(widthBytes * height);
    final darkLimit = 255 - threshold;

    for (var y = 0; y < height; y++) {
      var pixelIndex = y * width * 4;
      var outputIndex = y * widthBytes;
      var accumulator = 0;
      var bitCount = 0;

      for (var x = 0; x < width; x++) {
        var red = rgba[pixelIndex];
        var green = rgba[pixelIndex + 1];
        var blue = rgba[pixelIndex + 2];
        final alpha = rgba[pixelIndex + 3];

        if (alpha != 255) {
          final inverse = 255 - alpha;
          if (premultipliedAlpha) {
            red = _clampByte(red + inverse);
            green = _clampByte(green + inverse);
            blue = _clampByte(blue + inverse);
          } else {
            red = (red * alpha + 255 * inverse) ~/ 255;
            green = (green * alpha + 255 * inverse) ~/ 255;
            blue = (blue * alpha + 255 * inverse) ~/ 255;
          }
        }

        final luminance = (299 * red + 587 * green + 114 * blue) ~/ 1000;
        accumulator = (accumulator << 1) | (luminance < darkLimit ? 1 : 0);

        if (++bitCount == 8) {
          output[outputIndex++] = accumulator;
          accumulator = 0;
          bitCount = 0;
        }
        pixelIndex += 4;
      }

      if (bitCount != 0) {
        output[outputIndex] = accumulator << (8 - bitCount);
      }
    }

    return output;
  }

  static int _clampByte(int value) => value > 255 ? 255 : value;
}
