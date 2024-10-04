part of '../flutter_bluetooth_printer_web_library.dart';

/// Type of CharacteristicProperties .
/// See : https://developer.mozilla.org/en-US/docs/Web/API/BluetoothCharacteristicProperties
///
///
extension type BluetoothCharacteristicProperties._(JSObject _)
    implements JSObject {
  external JSBoolean get broadcast;

  external JSBoolean get read;

  external JSBoolean get writeWithoutResponse;

  external JSBoolean get write;

  external JSBoolean get notify;

  external JSBoolean get indicate;

  external JSBoolean get authenticatedSignedWrite;

  external JSBoolean get reliableWrite;

  external JSBoolean get writableAuxiliaries;
}

/// Type Of GATTCharacteristic
/// See : https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTCharacteristic
///
///
extension type BluetoothDeviceGATTCharacteristic._(JSObject _)
    implements web.EventTarget, JSObject {
  external JSString get uuid;

  external BluetoothCharacteristicProperties get properties;

  external JSDataView get value;

  external JSPromise<BluetoothGATTDescriptor> getDescriptor();

  external JSPromise<JSArray<BluetoothGATTDescriptor>> getDescriptors();

  external JSPromise<JSDataView> readValue();

  external JSPromise<JSAny?> writeValueWithResponse(JSUint8Array value);

  external JSPromise<JSAny?> writeValueWithoutResponse(JSUint8Array value);

  external JSPromise<JSAny?> startNotification();

  external JSPromise<JSAny?> stopNotification();

  // Not implemented yet .
  external web.EventHandler get characteristicvaluechanged;
  external set characteristicvaluechanged(web.EventHandler value);
}

/// Type Of GATTDescriptor
/// See : https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTDescriptor
///
///
extension type BluetoothGATTDescriptor._(JSObject _) implements JSObject {
  external BluetoothDeviceGATTCharacteristic get characteristic;

  external JSString get uuid;

  external JSArrayBuffer get value;
}

/// Type Of GATTService
/// See : https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTService
///
///
extension type BlutoothDeviceGATTService._(JSObject _)
    implements web.EventTarget, JSObject {
  external WebBluetoothDevice get device;

  external JSBoolean get isPrimary;

  external JSString get uuid;

  external JSPromise<BluetoothDeviceGATTCharacteristic> getCharacteristic(
      JSString characteristic);

  external JSPromise<JSArray<BluetoothDeviceGATTCharacteristic>>
      getCharacteristics(JSString? characteristic);
}

/// Type of GATTServer
/// See : https://developer.mozilla.org/en-US/docs/Web/API/BluetoothRemoteGATTServer
///
///
extension type BluetoothDeviceGATTServer._(JSObject _) implements JSObject {
  external WebBluetoothDevice get device;

  external JSBoolean get connected;

  external JSPromise<JSAny?> connect();

  external void disconnect();

  external JSPromise<BlutoothDeviceGATTService> getPrimaryService(
      JSString bluetoothServiceUUID);

  external JSPromise<JSArray<BlutoothDeviceGATTService>> getPrimaryServices(
      JSString? bluetoothServiceUUID);
}
