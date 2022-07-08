import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({Key? key}) : super(key: key);

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  ReceiptController? controller;
  String? address;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Page'),
        actions: [
          IconButton(
            onPressed: () async {
              final selected =
                  await FlutterBluetoothPrinter.selectDevice(context);
              if (selected != null) {
                setState(() {
                  address = selected.address;
                });
              }
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Receipt(
              builder: (context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FittedBox(
                      fit: BoxFit.cover,
                      child: Text(
                        'PURCHASE RECEIPT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(thickness: 4),
                    Row(
                      children: const [
                        Text(
                          'Date:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '2020-01-01',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(thickness: 4),
                    for (int i = 0; i < 10; i++)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${i + 1}. Product',
                            ),
                          ),
                          const Text(
                            '10000',
                          ),
                        ],
                      ),
                    const Divider(thickness: 4),
                    FittedBox(
                      fit: BoxFit.cover,
                      child: Row(
                        children: const [
                          Text(
                            'TOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            '23456780',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 4),
                    const Text('Thank you for your purchase!'),
                  ],
                );
              },
              onInitialized: (controller) {
                this.controller = controller;
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final selectedAddress = address ??
                  (await FlutterBluetoothPrinter.selectDevice(context))
                      ?.address;

              if (selectedAddress != null) {
                controller?.print(address: selectedAddress);
              }
            },
            child: const Text('PRINT'),
          ),
        ],
      ),
    );
  }
}
