import 'dart:typed_data';

import 'raster_packer.dart';

class RasterCommandBuilder {
  const RasterCommandBuilder._();

  static const int _maxDimension = 0xFFFF;
  static const int _densityNormal = 0;
  static const int _headerTailLength = 5;

  static Uint8List build({
    required List<int> commandPrefix,
    required Uint8List rasterData,
    required int widthPx,
    required int heightPx,
  }) {
    final widthBytes = RasterPacker.bytesPerRow(widthPx);

    if (widthBytes > _maxDimension || heightPx > _maxDimension) {
      throw RangeError(
        'Raster size exceeds command limit: ${widthBytes}B x ${heightPx}px',
      );
    }
    if (rasterData.length != widthBytes * heightPx) {
      throw ArgumentError.value(
        rasterData.length,
        'rasterData',
        'Data length must be ${widthBytes * heightPx} byte',
      );
    }

    final headerLength = commandPrefix.length + _headerTailLength;
    final output = Uint8List(headerLength + rasterData.length);

    output.setAll(0, commandPrefix);
    var index = commandPrefix.length;
    output[index++] = _densityNormal;
    output[index++] = widthBytes & 0xFF; // xL
    output[index++] = (widthBytes >> 8) & 0xFF; // xH
    output[index++] = heightPx & 0xFF; // yL
    output[index] = (heightPx >> 8) & 0xFF; // yH

    output.setAll(headerLength, rasterData);
    return output;
  }
}
