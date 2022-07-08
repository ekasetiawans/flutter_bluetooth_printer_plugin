import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:flutter_bluetooth_printer_example/build_pdf.dart';

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
  final bluetoothPrinter = BluetoothPrinter();
  BluetoothDevice? _device;

  @override
  void dispose() {
    bluetoothPrinter.dispose();
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
            if (_device == null)
              ElevatedButton(
                onPressed: () async {
                  final selected = await showDialog(
                    context: context,
                    builder: (context) => BluetoothDeviceSelector(
                      bluetoothPrinter: bluetoothPrinter,
                    ),
                  );
                  if (selected is BluetoothDevice) {
                    setState(() {
                      _device = selected;
                    });
                  }
                },
                child: const Text('Select Device'),
              ),
            if (_device != null) ...[
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _device = null;
                  });
                },
                child: const Text('Change Device'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_device!.isConnected) {
                    await _device!.disconnect();
                  } else {
                    await _device!.connect();
                  }
                  setState(() {});
                },
                child: _device!.isConnected
                    ? Text('Disconnect from ${_device!.name}')
                    : Text('Connect to ${_device!.name}'),
              ),
            ],
            if (_device?.isConnected ?? false) ...[
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
                  _device?.printPdf(data: data);
                },
                child: const Text('Print Image'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class BluetoothDeviceSelector extends StatefulWidget {
  final BluetoothPrinter bluetoothPrinter;
  const BluetoothDeviceSelector({
    Key? key,
    required this.bluetoothPrinter,
  }) : super(key: key);

  @override
  State<BluetoothDeviceSelector> createState() =>
      _BluetoothDeviceSelectorState();
}

class _BluetoothDeviceSelectorState extends State<BluetoothDeviceSelector> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: StreamBuilder<List<BluetoothDevice>>(
        stream: widget.bluetoothPrinter.discoveredDevices,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data ?? [];
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices.elementAt(index);
              return ListTile(
                title: Text(device.name ?? device.address),
                trailing: device.isConnected ? const Text('Connected') : null,
                onTap: () async {
                  Navigator.pop(context, device);
                },
              );
            },
          );
        },
      ),
    );
  }
}
