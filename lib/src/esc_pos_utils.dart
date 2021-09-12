import 'package:image/image.dart';

class PrinterUtils {
  final List<int> initializePrinter = <int>[0x1B, 0x40];

  final List<int> printAndFeedPaper = <int>[0x0A];

  final List<int> selectBitImageMode = <int>[0x1B, 0x2A];
  final List<int> setLineSpacing = <int>[0x1B, 0x33];

  int maxBitsWidth = 255;
  PrinterUtils();

  List<int> _buildPOSCommand(List<int> command, List<int> args) {
    List<int> posCommand = <int>[...command, ...args];
    return posCommand;
  }

  List<bool> _getBitsImageData(Image image) {
    int index = 0;
    int dimension = image.width * image.height;
    List<bool> imageBitsData = List<bool>.generate(dimension, (index) => false);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        int color = image.getPixel(x, y);

        int r = (color >> 24) & 0xff;
        int g = (color >> 16) & 0xff;
        int b = (color >> 8) & 0xff;
        int a = color & 0xff;

        // if color close to white，bit='0', else bit='1'
        if (a < 160 || (r > 160 && g > 160 && b > 160)) {
          imageBitsData[index] = false;
        } else {
          imageBitsData[index] = true;
        }

        index++;
      }
    }

    return imageBitsData;
  }

  List<int> decodeImage(Image image) {
    final List<int> printOutput = [];
    List<bool> imageBits = _getBitsImageData(image);

    int widthLSB = (image.width & 0xFF);
    int widthMSB = ((image.width >> 8) & 0xFF);

    // COMMANDS
    List<int> selectBitImageModeCommand =
        _buildPOSCommand(selectBitImageMode, <int>[33, widthLSB, widthMSB]);
    List<int> setLineSpacing24Dots =
        _buildPOSCommand(setLineSpacing, <int>[24]);
    List<int> setLineSpacing30Dots =
        _buildPOSCommand(setLineSpacing, <int>[30]);

    printOutput.addAll(initializePrinter);
    printOutput.addAll(setLineSpacing24Dots);

    int offset = 0;
    while (offset < image.height) {
      printOutput.addAll(selectBitImageModeCommand);

      int imageDataLineIndex = 0;
      List<int> imageDataLine =
          List<int>.generate(3 * image.width, (index) => 0);

      for (int x = 0; x < image.width; ++x) {
        // Remember, 24 dots = 24 bits = 3 bytes.
        // The 'k' variable keeps track of which of those
        // three bytes that we're currently scribbling into.
        for (int k = 0; k < 3; ++k) {
          int slice = 0;

          // A byte is 8 bits. The 'b' variable keeps track
          // of which bit in the byte we're recording.
          for (int b = 0; b < 8; ++b) {
            // Calculate the y position that we're currently
            // trying to draw. We take our offset, divide it
            // by 8 so we're talking about the y offset in
            // terms of bytes, add our current 'k' byte
            // offset to that, multiple by 8 to get it in terms
            // of bits again, and add our bit offset to it.
            int y = (((offset ~/ 8) + k) * 8) + b;

            // Calculate the location of the pixel we want in the bit array.
            // It'll be at (y * width) + x.
            int i = (y * image.width) + x;

            // If the image (or this stripe of the image)
            // is shorter than 24 dots, pad with zero.
            bool v = false;
            if (i < imageBits.length) {
              v = imageBits[i];
            }
            // Finally, store our bit in the byte that we're currently
            // scribbling to. Our current 'b' is actually the exact
            // opposite of where we want it to be in the byte, so
            // subtract it from 7, shift our bit into place in a temp
            // byte, and OR it with the target byte to get it into there.
            slice |= ((v ? 1 : 0) << (7 - b));
          }

          imageDataLine[imageDataLineIndex + k] = slice;

          // Phew! Write the damn byte to the buffer
          //printOutput.write(slice);
        }

        imageDataLineIndex += 3;
      }

      printOutput.addAll(imageDataLine);
      offset += 24;
      printOutput.addAll(printAndFeedPaper);
    }

    printOutput.addAll(setLineSpacing30Dots);
    return printOutput;
  }
}
