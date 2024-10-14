part of flutter_bluetooth_printer_web;

extension type RequestDeviceJS._(JSObject _) implements JSObject {
  external JSBoolean get acceptAllDevices;

  external JSArray<ScanFilterJSObject> get filters;

  external JSArray<ScanFilterJSObject> get exclusionFilters;

  external JSArray<JSString> get optionalServices;

  external JSArray<JSNumber> get optionalManufacturerData;

  external RequestDeviceJS({
    final JSBoolean acceptAllDevices,
    final JSArray<ScanFilterJSObject> filters,
    final JSArray<ScanFilterJSObject> exclusionFilters,
    final JSArray<JSString> optionalServices,
    final JSArray<JSNumber> optionalManufacturerData,
  });
}
