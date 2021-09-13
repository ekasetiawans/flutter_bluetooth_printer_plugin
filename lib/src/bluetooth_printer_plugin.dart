import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_printer/src/bluetooth_device.dart';
import 'package:image/image.dart' as img;
import 'package:native_pdf_renderer/native_pdf_renderer.dart' as rd;

class BluetoothPrinter {
  static final instance = BluetoothPrinter._();
  final _channel = const MethodChannel('id.flutter.plugins/bluetooth_printer');

  final _discoverController =
      StreamController<List<BluetoothDevice>>.broadcast();

  final _stateController = StreamController<int>.broadcast();

  final _printingProgress = StreamController<Map<String, dynamic>>.broadcast();

  Stream<List<BluetoothDevice>> get scanResults => _discoverController.stream;
  Stream<int> get stateChanged => _stateController.stream;

  final List<BluetoothDevice> _devices = [];
  BluetoothPrinter._() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDiscovered':
          final dev = call.arguments;
          final device = BluetoothDevice(
            name: dev['name'],
            address: dev['address'],
            type: dev['type'],
          );

          if (!_devices.any((element) => element.address == device.address)) {
            _devices.add(device);
            _discoverController.sink.add(_devices);
          }
          break;

        case 'onStateChanged':
          int id = call.arguments['id'];
          _stateController.sink.add(id);
          break;

        case 'onPrintingProgress':
          int total = call.arguments['total'];
          int progress = call.arguments['progress'];
          _printingProgress.sink.add({
            'total': total,
            'progress': progress,
          });
          break;
        default:
      }

      return true;
    });

    stateChanged.listen((event) {
      if (event == 3) {
        _connectedDevice = null;
      }
    });
  }

  Future<bool> isEnabled() async {
    return await _channel.invokeMethod('isEnabled');
  }

  Future<void> startScan() async {
    _devices.clear();
    _discoverController.sink.add(_devices);
    await _channel.invokeMethod('startScan');
  }

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<bool> connect(BluetoothDevice device) async {
    final completer = Completer<bool>();
    final subscriber = stateChanged.listen((event) {
      if (event == 1) {
        completer.complete(true);
        return;
      }

      if (event == 4 || event == 2) {
        completer.complete(false);
        return;
      }
    });

    try {
      await _channel.invokeMethod('connect', {
        'address': device.address,
      });

      final res = await completer.future;
      if (res) {
        _connectedDevice = device;
      }
      return res;
    } catch (e) {
      return false;
    } finally {
      subscriber.cancel();
    }
  }

  Future<void> disconnect() async {
    await _channel.invokeMethod('disconnect');
  }

  Future<void> stopScan() async {
    await _channel.invokeMethod('stopScan');
  }

  Future<void> printBytes({
    required Uint8List bytes,
    void Function(int total, int progress)? progress,
  }) async {
    final completer = Completer<bool>();
    StreamSubscription? listener;
    listener = _printingProgress.stream.listen((event) {
      final int t = event['total'];
      final int p = event['progress'];
      if (progress != null) {
        progress(t, p);
      }

      if (t == p) {
        listener?.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    await _channel.invokeMethod(
      'print',
      {
        'bytes': base64.encode(bytes),
        'length': bytes.length,
      },
    );

    await completer.future;
  }

  Future<void> printImage({
    required img.Image image,
    PaperSize paperSize = PaperSize.mm58,
    void Function(int total, int progress)? progress,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final data = generator.image(image);

    await printBytes(
      bytes: Uint8List.fromList(data),
      progress: progress,
    );
  }

  Future<void> printPdf({
    required Uint8List data,
    int pageNumber = 1,
    PaperSize paperSize = PaperSize.mm58,
    void Function(int total, int progress)? progress,
  }) async {
    final doc = await rd.PdfDocument.openData(data);
    final page = await doc.getPage(pageNumber);

    final pageImage = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: rd.PdfPageFormat.JPEG,
    );

    final image = img.decodeJpg(pageImage!.bytes);
    return printImage(
      image: image,
      paperSize: paperSize,
      progress: progress,
    );
  }
}
