part of flutter_bluetooth_printer;

class BluetoothDeviceSelector extends StatefulWidget {
  final Widget? disabledWidget;
  final Widget? permissionRestrictedWidget;
  final Widget? title;
  const BluetoothDeviceSelector({
    Key? key,
    this.disabledWidget,
    this.permissionRestrictedWidget,
    this.title,
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: widget.title ??
              const Text(
                'Choose a device',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
        ),
        Expanded(
          child: StreamBuilder<DiscoveryState>(
            stream: FlutterBluetoothPrinter.discovery,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data;

              if (data is BluetoothDisabledState) {
                return widget.disabledWidget ??
                    const Center(
                      child: Text('Bluetooth is disabled'),
                    );
              }

              if (data is PermissionRestrictedState) {
                return widget.permissionRestrictedWidget ??
                    const Center(
                      child: Text('Bluetooth is not permitted'),
                    );
              }

              if (data is BluetoothEnabledState) {
                return const Center(child: CircularProgressIndicator());
              }

              final devices = (data as DiscoveryResult).devices;
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
          ),
        ),
      ],
    );
  }
}
