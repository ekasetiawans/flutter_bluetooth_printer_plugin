part of flutter_bluetooth_printer_macos;

class CUPSPrinterDriver extends FlutterBluetoothPrinterPlatform {
  static void registerWith() {
    FlutterBluetoothPrinterPlatform.instance = CUPSPrinterDriver();
  }

  @override
  Future<bool> disconnect(String address) async {
    //no need to disconnect
    return true;
  }

  @override
  Stream<DiscoveryState> get discovery => _discovery();

  Stream<DiscoveryState> _discovery() async* {
    final process = await Process.run('lpstat', ['-p']);
    final output = process.stdout.toString().split('\n');
    for (final line in output) {
      if (line.startsWith('printer') && line.contains('is idle')) {
        final printerName = line
            .substring('printer '.length, line.indexOf(' ', 'printer '.length))
            .trim();
        yield BluetoothDevice(
          address: printerName,
          name: printerName,
        );
      }
    }
  }

  @override
  Future<bool> write({
    required String address,
    required Uint8List data,
    bool keepConnected = false,
    required int maxBufferSize,
    required int delayTime,
    ProgressCallback? onProgress,
  }) async {
    final prnFile = File('tmp.prn');
    await prnFile.writeAsBytes(data);

    final process = await Process.start(
      'lpr',
      ['-P', address, "tmp.prn"],
    );

    await process.exitCode;
    await prnFile.delete();
    onProgress?.call(1, 1);
    return true;
  }

  @override
  Future<bool> connect(String address) async {
    return true;
  }

  @override
  Future<BluetoothState> checkState() async  {
    return BluetoothState.enabled;
  }
}
