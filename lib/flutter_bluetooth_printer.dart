// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

library bluetooth_printer;

import 'dart:async';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:image/image.dart' as img;
import 'package:native_pdf_renderer/native_pdf_renderer.dart' as rd;

export 'package:esc_pos_utils_plus/esc_pos_utils.dart';

part 'src/bluetooth_device.dart';
part 'src/bluetooth_printer_plugin.dart';
