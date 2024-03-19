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
              backgroundColor: Colors.grey.shade200,
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
                    const FittedBox(
                      fit: BoxFit.cover,
                      child: Row(
                        children: [
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
                setState(() {
                  this.controller = controller;
                });
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final selectedAddress = address ??
                            (await FlutterBluetoothPrinter.selectDevice(
                                    context))
                                ?.address;

                        if (selectedAddress != null) {
                          PrintingProgressDialog.print(
                            context,
                            device: selectedAddress,
                            controller: controller!,
                          );
                        }
                      },
                      child: const Text('PRINT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrintingProgressDialog extends StatefulWidget {
  final String device;
  final ReceiptController controller;
  const PrintingProgressDialog({
    Key? key,
    required this.device,
    required this.controller,
  }) : super(key: key);

  @override
  State<PrintingProgressDialog> createState() => _PrintingProgressDialogState();
  static void print(
    BuildContext context, {
    required String device,
    required ReceiptController controller,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrintingProgressDialog(
        controller: controller,
        device: device,
      ),
    );
  }
}

class _PrintingProgressDialogState extends State<PrintingProgressDialog> {
  double? progress;
  @override
  void initState() {
    super.initState();
    widget.controller.print(
      address: widget.device,
      addFeeds: 5,
      keepConnected: true,
      onProgress: (total, sent) {
        if (mounted) {
          setState(() {
            progress = sent / total;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Printing Receipt',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 4),
            Text('Processing: ${((progress ?? 0) * 100).round()}%'),
            if (((progress ?? 0) * 100).round() == 100) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await FlutterBluetoothPrinter.disconnect(widget.device);
                  Navigator.pop(context);
                },
                child: const Text('Disconnect'),
              )
            ]
          ],
        ),
      ),
    );
  }
}
