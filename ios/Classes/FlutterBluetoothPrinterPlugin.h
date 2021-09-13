#import <Flutter/Flutter.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ConnecterManager.h"

#define NAMESPACE @"flutter_bluetooth_printer"

@interface FlutterBluetoothPrinterPlugin : NSObject<FlutterPlugin>
@property(nonatomic,copy)ConnectDeviceState state;
@end
