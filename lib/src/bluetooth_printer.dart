part of flutter_bluetooth_printer;

abstract class BluetoothPrinter {
  Stream<List<BluetoothDevice>> get discoveredDevices;
  Future<BluetoothDevice?> getDevice({
    required String address,
    Duration timeout = const Duration(seconds: 15),
  });
  void dispose();

  factory BluetoothPrinter() => _instance;
  static void setMock(BluetoothPrinter mock) {
    _instance = mock;
  }
}

abstract class BluetoothDevice {
  final String address;
  final String? name;
  final int type;

  BluetoothDevice({
    required this.address,
    this.name,
    required this.type,
  });

  Future<bool> connect();
  Future<bool> disconnect();
  Future<void> printBytes({
    required Uint8List bytes,
    void Function(int total, int progress)? progress,
  });
  Future<void> printImage({
    required img.Image image,
    PaperSize paperSize = PaperSize.mm58,
    void Function(int total, int progress)? progress,
  });
  Future<void> printPdf({
    required Uint8List data,
    int pageNumber = 1,
    PaperSize paperSize = PaperSize.mm58,
    void Function(int total, int progress)? progress,
  });

  bool get isConnected;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDevice && other.address == address;

  @override
  int get hashCode => address.hashCode;
}

BluetoothPrinter _instance = _BluetoothPrinterImpl();
