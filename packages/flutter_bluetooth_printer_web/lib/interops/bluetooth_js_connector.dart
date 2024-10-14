part of flutter_bluetooth_printer_web;

extension BluetoothNavEx on web.Navigator {
  external Bluetooth get bluetooth;

  bool get isBluetoothSupported => hasProperty(bluetooth).toDart;
}

extension type Bluetooth._(JSObject _) implements web.EventTarget, JSObject {
  external JSPromise<JSBoolean> getAvailability();

  external JSPromise<LEScanResult> requestLEScan(LEScanRequest options);

  external JSPromise<WebBluetoothDevice> requestDevice(RequestDeviceJS options);

  external JSPromise<JSArray<WebBluetoothDevice>> getDevices();

  external web.EventHandler get advertisementreceived;
  external set advertisementreceived(web.EventHandler value);

  external web.EventHandler get availabilitychanged;
  external set availabilitychanged(web.EventHandler value);

  static const web.EventStreamProvider<AdvertisementDeviceResult>
      advertisementReceivedEvent =
      web.EventStreamProvider<AdvertisementDeviceResult>(
          'advertisementreceived');

  Stream<AdvertisementDeviceResult> get advertisementReceivedStream =>
      Bluetooth.advertisementReceivedEvent.forTarget(this);
}
