#import <Flutter/Flutter.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ConnecterManager.h"

#define NAMESPACE @"flutter_bluetooth_printer"

@interface FlutterBluetoothPrinterPlugin : NSObject<FlutterPlugin, FlutterStreamHandler>
@property(nonatomic,copy)ConnectDeviceState state;
@end

@interface FlutterBluetoothDevice: NSObject
@property NSString* address;
- (id) initWithPeripheral:(CBPeripheral*)peripheral
          binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;
@end
