import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:flutter_bluetooth_printer_example/build_pdf.dart';
import 'package:flutter_bluetooth_printer_example/receipt_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BluetoothDevice? _device;
  double? _progress;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReceiptPage(),
                  ),
                );
              },
              child: const Text('Receipt'),
            ),
            ElevatedButton(
              onPressed: () async {
                final selected =
                    await FlutterBluetoothPrinter.selectDevice(context);
                if (selected is BluetoothDevice) {
                  setState(() {
                    _device = selected;
                  });
                }
              },
              child: const Text('Select Device'),
            ),
            if (_device != null) ...[
              const SizedBox(height: 48),
              Text(
                'Connected to ${_device!.name}',
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
              Text(
                _device!.address,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final data = await buildPdf();
                  FlutterBluetoothPrinter.printPdf(
                    address: _device!.address,
                    data: data,
                    onProgress: (total, sent) {
                      setState(() {
                        _progress = sent / total;
                      });
                    },
                  );
                },
                child: const Text('Print Image'),
              ),
              ValueListenableBuilder<BluetoothConnectionState>(
                valueListenable:
                    FlutterBluetoothPrinter.connectionStateNotifier,
                builder: (context, value, child) {
                  return Column(
                    children: [
                      Text(value.toString()),
                      if (value == BluetoothConnectionState.printing)
                        LinearProgressIndicator(
                          value: _progress,
                        ),
                    ],
                  );
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}
