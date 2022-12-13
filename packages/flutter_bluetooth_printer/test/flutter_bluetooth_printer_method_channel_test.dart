import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_method_channel.dart';

void main() {
  MethodChannelFlutterBluetoothPrinter platform = MethodChannelFlutterBluetoothPrinter();
  const MethodChannel channel = MethodChannel('flutter_bluetooth_printer');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
