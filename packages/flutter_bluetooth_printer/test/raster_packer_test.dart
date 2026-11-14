import 'dart:typed_data';

import 'package:flutter_bluetooth_printer/src/raster/raster_command_builder.dart';
import 'package:flutter_bluetooth_printer/src/raster/raster_packer.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _solidRgba(
  int width,
  int height, {
  required int red,
  required int green,
  required int blue,
  int alpha = 255,
}) {
  final data = Uint8List(width * height * 4);
  for (var i = 0; i < data.length; i += 4) {
    data[i] = red;
    data[i + 1] = green;
    data[i + 2] = blue;
    data[i + 3] = alpha;
  }
  return data;
}

void main() {
  group('RasterPacker', () {
    test('all black pixels become 0xFF', () {
      final rgba = _solidRgba(8, 1, red: 0, green: 0, blue: 0);
      final result = RasterPacker.pack(rgba: rgba, width: 8, height: 1);
      expect(result, [0xFF]);
    });

    test('all white pixels become 0x00', () {
      final rgba = _solidRgba(8, 1, red: 255, green: 255, blue: 255);
      final result = RasterPacker.pack(rgba: rgba, width: 8, height: 1);
      expect(result, [0x00]);
    });

    test('MSB first bit order', () {
      final rgba = _solidRgba(8, 1, red: 255, green: 255, blue: 255);
      rgba[0] = 0; // First pixel is black
      rgba[1] = 0;
      rgba[2] = 0;
      final result = RasterPacker.pack(rgba: rgba, width: 8, height: 1);
      expect(result, [0x80]);
    });

    test('width not a multiple of 8 white padding per row', () {
      final rgba = _solidRgba(10, 2, red: 0, green: 0, blue: 0);
      final result = RasterPacker.pack(rgba: rgba, width: 10, height: 2);
      expect(result, [0xFF, 0xC0, 0xFF, 0xC0]);
    });

    test('Threshold limit is the same as in the legacy version.', () {
      final dark = _solidRgba(8, 1, red: 126, green: 126, blue: 126);
      final light = _solidRgba(8, 1, red: 127, green: 127, blue: 127);
      expect(RasterPacker.pack(rgba: dark, width: 8, height: 1), [0xFF]);
      expect(RasterPacker.pack(rgba: light, width: 8, height: 1), [0x00]);
    });

    test('premultiplied transparent pixels are treated as white', () {
      final rgba = _solidRgba(8, 1, red: 0, green: 0, blue: 0, alpha: 0);
      final result = RasterPacker.pack(
        rgba: rgba,
        width: 8,
        height: 1,
        premultipliedAlpha: true,
      );
      expect(result, [0x00]);
    });

    test('Transparent pixels with straight alpha are treated as white.', () {
      final rgba = _solidRgba(8, 1, red: 0, green: 0, blue: 0, alpha: 0);
      final result = RasterPacker.pack(rgba: rgba, width: 8, height: 1);
      expect(result, [0x00]);
    });

    test('data too short, throws ArgumentError', () {
      expect(
        () => RasterPacker.pack(rgba: Uint8List(4), width: 8, height: 1),
        throwsArgumentError,
      );
    });
  });

  group('RasterCommandBuilder', () {
    test('Header contains prefix, mode, byte width, and height.', () {
      const prefix = [0x1D, 0x76, 0x30];
      final data = Uint8List(2 * 3); // L 10px = 2 byte, T 3
      final result = RasterCommandBuilder.build(
        commandPrefix: prefix,
        rasterData: data,
        widthPx: 10,
        heightPx: 3,
      );

      expect(result.sublist(0, 8), [0x1D, 0x76, 0x30, 0, 2, 0, 3, 0]);
      expect(result.length, 8 + data.length);
    });

    test('a data length mismatch throws an ArgumentError', () {
      expect(
        () => RasterCommandBuilder.build(
          commandPrefix: const [0x1D, 0x76, 0x30],
          rasterData: Uint8List(1),
          widthPx: 10,
          heightPx: 3,
        ),
        throwsArgumentError,
      );
    });
  });
}
