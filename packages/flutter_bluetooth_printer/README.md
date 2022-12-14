# flutter_bluetooth_printer

A flutter plugin for print a receipt over bluetooth thermal printer.

## Getting Started

Depend on it:

```yaml
  dependencies:
    flutter_bluetooth_printer: any
```

Make your receipt

```dart
  ReceiptController? controller;

  Widget build(BuildContext context){
    return Receipt(
        /// You can build your receipt widget that will be printed to the device
        /// Note that, this feature is in experimental, you should make sure your widgets will be fit on every device.
        builder: (context) => Column(
            children: [
                Text('Hello World'),
            ]
        ),
        onInitialized: (controller) {
            this.controller = controller;
        },
    );
  }
```

Select a device and print:

```dart
    Future<void> print() async {
        final device = await FlutterBluetoothPrinter.selectDevice(context);
        if (device != null){
            /// do print
            controller?.print(address: device.address);
        }
    }
```

## Custom Device Selector

You can make your own device selector using `FlutterBluetoothPrinter.discovery` stream to discover available devices.

```dart
  Widget build(BuilderContext context){
    return StreamBuilder<List<BluetoothDevice>>(
        stream: FlutterBluetoothPrinter.discovery,
        builder: (context, snapshot){

            final list = snapshot.data ?? <BluetoothDevice>[];
            return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index){
                    final device = list.elementAt(index);
                    return ListTile(
                        title: Text(device.name ?? 'No Name'),
                        subtitle: Text(device.address),
                        onTap: (){
                            // do anything
                            FlutterBluetoothPrinter.printImage(
                                address: device.address,
                                image: // some image
                            );
                        }
                    );
                }
            );
        }
    );
  }

```

## Print PDF or Image

You can print a PDF or an Image that contains your receipt design.
For a PDF file, you can use any package that convert your PDF to an image.
Then you can print it using command below:

```dart
FlutterBluetoothPrinter.printImage(...);
```

Note that, we are currently using package `image`.

## Print Custom ESC/POS Command
You still able to send an ESC/POS Command using command below:

```dart
FlutterBluetoothPrinter.printBytes(...);
```

## Do you like my work?

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/ekasetiawans)

## Discord

Click [here](https://discord.gg/aqk6JjBm) to join to my discord channels