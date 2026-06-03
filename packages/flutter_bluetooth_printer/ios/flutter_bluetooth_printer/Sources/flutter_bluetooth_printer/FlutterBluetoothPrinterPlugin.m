#import "FlutterBluetoothPrinterPlugin.h"
#if __has_include(<flutter_bluetooth_printer/flutter_bluetooth_printer-Swift.h>)
#import <flutter_bluetooth_printer/flutter_bluetooth_printer-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_bluetooth_printer-Swift.h"
#endif

@implementation FlutterBluetoothPrinterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterBluetoothPrinterPlugin registerWithRegistrar:registrar];
}
@end
