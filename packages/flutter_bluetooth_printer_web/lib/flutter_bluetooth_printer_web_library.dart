// import 'web';
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_bluetooth_printer_platform_interface/flutter_bluetooth_printer_platform_interface.dart';

part 'interops/bluetooth_js_connector.dart';
part 'interops/request_device_js.dart';
part 'interops/le_scan_result.dart';
part 'interops/bluetooth_device_gatt.dart';
part 'interops/bluetooth_device_result.dart';
part 'interops/advertisement_js_result.dart';
part 'interops/le_scan_request.dart';
part 'peripherals/bluetooth_discovery_manual.dart';
part 'peripherals/web_blueooth_dart_device.dart';
part 'peripherals/flutter_bluetooth_web_js_channel.dart';
