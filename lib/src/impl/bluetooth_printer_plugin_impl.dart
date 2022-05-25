part of flutter_bluetooth_printer;

class _BluetoothPrinterImpl implements BluetoothPrinter {
  final MethodChannel _channel =
      const MethodChannel('maseka.dev/bluetooth_printer');
  final _eventChannel =
      const EventChannel('maseka.dev/bluetooth_printer/discovery');

  final List<BluetoothDevice> _devices = [];
  @override
  Stream<List<BluetoothDevice>> get discoveredDevices => _eventChannel
          .receiveBroadcastStream(
              DateTime.now().millisecondsSinceEpoch.toString())
          .transform(
        StreamTransformer.fromHandlers(
          handleData: (event, sink) {
            final device = _BluetoothDeviceImpl(
              name: event['name'],
              address: event['address'],
              type: event['type'] ?? 1,
              isConnected: event['is_connected'] ?? false,
            );

            if (!_devices.contains(device)) {
              _devices.add(device);
            }

            sink.add(_devices);
          },
        ),
      );

  Future<BluetoothDevice?> _getDeviceByAddress(String address) async {
    await for (final devices in discoveredDevices) {
      final index = devices.indexWhere(
          (element) => element.address.toLowerCase() == address.toLowerCase());
      if (index >= 0) {
        return devices[index];
      }
    }

    return null;
  }

  @override
  Future<BluetoothDevice?> getDevice({
    required String address,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final result = _getDeviceByAddress(address);
    return result.timeout(timeout, onTimeout: () {
      return null;
    });
  }

  @override
  void dispose() {
    _channel.invokeMethod('dispose');
  }
}
