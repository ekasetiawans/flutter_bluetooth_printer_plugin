part of flutter_bluetooth_printer;

class BluetoothDeviceSelector extends StatefulWidget {
  const BluetoothDeviceSelector({
    Key? key,
  }) : super(key: key);

  @override
  State<BluetoothDeviceSelector> createState() =>
      _BluetoothDeviceSelectorState();
}

class _BluetoothDeviceSelectorState extends State<BluetoothDeviceSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Choose a device',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<BluetoothState>(
            stream: FlutterBluetoothPrinter.stateStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final value = snapshot.data;
              if (value == BluetoothState.notPermitted) {
                return const Center(
                  child: Text('Bluetooth is not permitted'),
                );
              }

              if (value == BluetoothState.disabled) {
                return const Center(
                  child: Text('Bluetooth is disabled'),
                );
              }

              return StreamBuilder<List<BluetoothDevice>>(
                stream: FlutterBluetoothPrinter.discovery,
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
                        title: Text(device.name ?? '(unknown)'),
                        subtitle: Text(device.address),
                        leading: const Icon(Icons.bluetooth),
                        onTap: () async {
                          Navigator.pop(context, device);
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
