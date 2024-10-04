part of '../flutter_bluetooth_printer_web_library.dart';

extension type LEScanRequest._(JSObject _) implements JSObject {
  external JSArray<ScanFilterJSObject> get filters;

  external JSBoolean get keepRepeatedDevices;

  external JSBoolean get acceptAllAdvertisements;

  external JSBoolean get listenOnlyGrantedDevices;

  external LEScanRequest({
    final JSArray<ScanFilterJSObject> filters,
    final JSBoolean keepRepeatedDevices,
    final JSBoolean acceptAllAdvertisements,
    final JSBoolean listenOnlyGrantedDevices,
  });
}

extension type ScanFilterJSObject._(JSObject _) implements JSObject {
  external JSArray<JSString>? get services;

  external JSString? get name;

  external JSString? get namePrefix;

  external JSArray<LEScanFilterManufacturerData>? get manufacturerData;

  external JSArray<LEScanFilterServiceData>? get serviceData;

  external ScanFilterJSObject({
    final JSArray<JSString>? services,
    final JSString? name,
    final JSString? namePrefix,
    final JSArray<LEScanFilterManufacturerData>? manufacturerData,
    final JSArray<LEScanFilterServiceData>? serviceData,
  });
}

extension type LEScanFilterManufacturerData._(JSObject _) implements JSObject {
  external int? get companyIdentifier;

  external JSObject? get dataPrefix;

  external JSObject? get mask;

  external LEScanFilterManufacturerData(
    final int? companyIdentifier,
    final JSObject? dataPrefix,
    final JSObject? mask,
  );
}

extension type LEScanFilterServiceData._(JSObject _) implements JSObject {
  external JSString? get service;

  external JSObject? get dataPrefix;

  external JSObject? get mask;

  external LEScanFilterServiceData(
    final JSString? service,
    final JSObject? dataPrefix,
    final JSObject? mask,
  );
}
