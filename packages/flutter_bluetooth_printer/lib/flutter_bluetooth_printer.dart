// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

library bluetooth_printer;

export 'package:esc_pos_utils_plus/esc_pos_utils.dart';
export 'package:flutter_bluetooth_printer_platform_interface/flutter_bluetooth_printer_platform_interface.dart'
    show BluetoothDevice, BluetoothConnectionState;

export 'flutter_bluetooth_printer_library.dart';
