part of flutter_bluetooth_printer_web;

extension type AdvertisementDeviceResult._(JSObject _)
    implements web.Event, JSObject {
  external JSArray<JSString> get uuids;

  external JSObject get manufacturerData;

  external JSObject get serviceData;

  Map<int, JSDataView> get dartManufacturerData {
    return manufacturerData.dartify() as Map<int, JSDataView>;
  }

  Map<int, JSDataView> get dartServiceData {
    return serviceData.dartify() as Map<int, JSDataView>;
  }

  external JSString get name;

  external int? get rssi;

  external int? get txPower;

  external int? get appearance;

  external WebBluetoothDevice get device;
}
