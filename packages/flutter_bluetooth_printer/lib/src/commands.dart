part of flutter_bluetooth_printer;

class Commands {
  // Initialization
  static const List<int> initialize = [0x1B, 0x40];

  // Text Formatting
  static const List<int> setBold = [0x1B, 0x45, 0x01];
  static const List<int> unsetBold = [0x1B, 0x45, 0x00];
  static const List<int> setUnderline = [0x1B, 0x2D, 0x01];
  static const List<int> unsetUnderline = [0x1B, 0x2D, 0x00];
  static const List<int> setFontA = [0x1B, 0x4D, 0x00];
  static const List<int> setFontB = [0x1B, 0x4D, 0x01];
  static const List<int> setAlignmentLeft = [0x1B, 0x61, 0x00];
  static const List<int> setAlignmentCenter = [0x1B, 0x61, 0x01];
  static const List<int> setAlignmentRight = [0x1B, 0x61, 0x02];

  // Paper Handling
  static const List<int> lineFeed = [0x0A];
  static const List<int> cutPaper = [0x1D, 0x56, 0x00];
  static const List<int> partialCutPaper = [0x1D, 0x56, 0x01];

  // Barcodes
  static const List<int> printBarcode = [0x1D, 0x6B];
  static const List<int> selectBarcodeTypeUPCA = [0x41];
  static const List<int> selectBarcodeTypeCODE39 = [0x43];
  static const List<int> selectBarcodeTypeCODE128 = [0x6B];

  // Miscellaneous
  static const List<int> enableAutoCutter = [0x1D, 0x56, 0x01];
  static const List<int> disableAutoCutter = [0x1D, 0x56, 0x00];
}
