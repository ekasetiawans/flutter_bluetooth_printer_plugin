part of '../flutter_bluetooth_printer_web_library.dart';

/// Type of BluetoothDevice
/// See : https://developer.mozilla.org/en-US/docs/Web/API/BluetoothDevice
///
///
extension type WebBluetoothDevice._(JSObject _)
    implements web.EventTarget, JSObject {
  external JSString get id;

  external JSString get name;

  external BluetoothDeviceGATTServer get gatt;

  // No docs yet
  external JSPromise<JSAny?> watchAdvertisements();

  // No docs yet
  external void forget();

  // No docs yet
  external web.EventHandler get gattserverdisconnect;
  external set gattserverdisconnect(web.EventHandler value);
}
