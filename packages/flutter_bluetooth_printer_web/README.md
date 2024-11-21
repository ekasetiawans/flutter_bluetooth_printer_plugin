# flutter\_bluetooth\_printer\_web

The web implementation of [`flutter_bluetooth_printer`][1].

## Usage

This package is [endorsed][2], which means you can simply use `flutter_bluetooth_printer`
normally. This package will be automatically included in your app when you do,
so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package to use any of its APIs directly, you
should add it to your `pubspec.yaml` as usual.

[1]: https://pub.dev/packages/flutter_bluetooth_printer
[2]: https://flutter.dev/to/endorsed-federated-plugin

## Limitations on the Web platform

### Using experimental web bluetooth API

The implementation of this packages rely on Experimental Web Bluetooth API .

Some of browser maybe doesn't support Web Bluetooth at all .

Read more: Bluetooth > [Web Bluetooth API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Bluetooth_API).

### Repairing device again after refreshing browser .

Paired bluetooth device are currently saved on internal states due to get Devices API still on early development .

Read more: Bluetooth > [Web Bluetooth Get Devices](https://developer.mozilla.org/en-US/docs/Web/API/Bluetooth/getDevices).