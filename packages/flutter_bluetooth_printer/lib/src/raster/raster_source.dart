import 'dart:typed_data';

import 'package:image/image.dart' as img;

class RasterSource {
  const RasterSource({
    required this.rgba,
    required this.width,
    required this.height,
    required this.premultipliedAlpha,
  });

  static const List<int> _pngSignature = [0x89, 0x50, 0x4E, 0x47];

  final Uint8List rgba;
  final int width;
  final int height;
  final bool premultipliedAlpha;

  factory RasterSource.from(
    Uint8List bytes, {
    int? sourceWidth,
    int? sourceHeight,
  }) {
    if (_isPng(bytes)) {
      return RasterSource.fromPng(bytes);
    }

    if (sourceWidth == null || sourceHeight == null) {
      throw ArgumentError(
        'sourceWidth and sourceHeight must be provided for raw RGBA data',
      );
    }

    return RasterSource.fromRawRgba(
      bytes,
      width: sourceWidth,
      height: sourceHeight,
    );
  }

  factory RasterSource.fromPng(Uint8List pngBytes) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) {
      throw const FormatException('Invalid PNG data');
    }

    final image = decoded.format == img.Format.uint8
        ? decoded
        : decoded.convert(format: img.Format.uint8);

    return RasterSource(
      rgba: image.getBytes(order: img.ChannelOrder.rgba),
      width: image.width,
      height: image.height,
      premultipliedAlpha: false,
    );
  }

  factory RasterSource.fromRawRgba(
    Uint8List rgba, {
    required int width,
    required int height,
  }) {
    return RasterSource(
      rgba: rgba,
      width: width,
      height: height,
      premultipliedAlpha: true,
    );
  }

  RasterSource fitToWidth(int widthPx) {
    if (width == widthPx) return this;

    final source = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgba.buffer,
      bytesOffset: rgba.offsetInBytes,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );

    final resized = img.copyResize(
      source,
      width: widthPx,
      maintainAspect: true,
      interpolation: img.Interpolation.cubic,
    );

    return RasterSource(
      rgba: resized.getBytes(order: img.ChannelOrder.rgba),
      width: resized.width,
      height: resized.height,
      premultipliedAlpha: premultipliedAlpha,
    );
  }

  static bool _isPng(Uint8List bytes) {
    if (bytes.length < _pngSignature.length) return false;
    for (var i = 0; i < _pngSignature.length; i++) {
      if (bytes[i] != _pngSignature[i]) return false;
    }
    return true;
  }
}
