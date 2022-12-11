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
                    Image.asset(
                      'assets/logo.webp',
                      fit: BoxFit.fitHeight,
                      height: 200,
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 36,
                      ),
                      child: const FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          'PURCHASE RECEIPT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Divider(thickness: 2),
                    Table(
                      columnWidths: const {
                        1: IntrinsicColumnWidth(),
                      },
                      children: const [
                        TableRow(
                          children: [
                            Text('ORANGE JUICE'),
                            Text(r'$2'),
                          ],
                        ),
                        TableRow(
                          children: [
                            Text('CAPPUCINO MEDIUM SIZE'),
                            Text(r'$2.9'),
                          ],
                        ),
                        TableRow(
                          children: [
                            Text('BEEF PIZZA'),
                            Text(r'$15.9'),
                          ],
                        ),
                        TableRow(
                          children: [
                            Text('ORANGE JUICE'),
                            Text(r'$2'),
                          ],
                        ),
                        TableRow(
                          children: [
                            Text('CAPPUCINO MEDIUM SIZE'),
                            Text(r'$2.9'),
                          ],
                        ),
                        TableRow(
                          children: [
                            Text('BEEF PIZZA'),
                            Text(r'$15.9'),
                          ],
                        ),
                      ],
                    ),
                    const Divider(thickness: 2),
                    FittedBox(
                      fit: BoxFit.cover,
                      child: Row(
                        children: const [
                          Text(
                            'TOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            r'$200',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 2),
                    const Text('Thank you for your purchase!'),
                    const SizedBox(height: 24),
                    Center(
                      child: Image.asset(
                        'assets/qrcode.png',
                        width: 150,
                      ),
                    ),
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
                controller?.print(
                  address: selectedAddress,
                  linesAfter: 2,
                );
              }
            },
            child: const Text('PRINT'),
          ),
        ],
      ),
    );
  }
}
