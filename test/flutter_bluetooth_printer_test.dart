import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel channel =
      MethodChannel('id.flutter.plugins/bluetooth_printer');
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return [];
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getBondedDevices', () async {
    //expect(await BluetoothPrinter.instance.getBondedDevices(), []);
  });
}
