#import "FlutterBluetoothPrinterPlugin.h"
#import "ConnecterManager.h"

@interface FlutterBluetoothPrinterPlugin ()
@property(nonatomic, retain) NSObject<FlutterPluginRegistrar> *registrar;
@property(nonatomic, retain) FlutterMethodChannel *channel;
@property(nonatomic) NSMutableDictionary *scannedPeripherals;
@end

@implementation FlutterBluetoothPrinterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"id.flutter.plugins/bluetooth_printer"
            binaryMessenger:[registrar messenger]];
    
  FlutterBluetoothPrinterPlugin* instance = [[FlutterBluetoothPrinterPlugin alloc] init];
  instance.channel = channel;
  instance.scannedPeripherals = [NSMutableDictionary new];
    
    
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"startScan" isEqualToString:call.method]) {
      [self.scannedPeripherals removeAllObjects];
      
        if (Manager.bleConnecter == nil) {
            [Manager didUpdateState:^(NSInteger state) {
                switch (state) {
                    case CBManagerStateUnsupported:
                        NSLog(@"The platform/hardware doesn't support Bluetooth Low Energy.");
                        break;
                    case CBManagerStateUnauthorized:
                        NSLog(@"The app is not authorized to use Bluetooth Low Energy.");
                        break;
                    case CBManagerStatePoweredOff:
                        NSLog(@"Bluetooth is currently powered off.");
                        break;
                    case CBManagerStatePoweredOn:
                        [self startScan];
                        NSLog(@"Bluetooth power on");
                        break;
                    case CBManagerStateUnknown:
                    default:
                        break;
                }
            }];
        } else {
            [self startScan];
        }
      
      result(@(YES));
  } else if ([@"stopScan" isEqualToString:call.method]){
      [Manager stopScan];
      result(@(YES));
  } else if ([@"isEnabled" isEqualToString:call.method]){
      result(@(YES));
  } else if ([@"print" isEqualToString:call.method]){
      @try {
         NSDictionary *args = [call arguments];
         NSString *str = [args objectForKey:@"bytes"];

         NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:str options:0];
          [Manager write:decodedData progress:^(NSUInteger total, NSUInteger progress) {
              NSDictionary *res = @{@"total": @(total), @"progress": @(progress)};
              [self->_channel invokeMethod:@"onPrintingProgress" arguments:res];
          } receCallBack:^(NSData * _Nullable data) {
              result(@(YES));
          }];
     } @catch(FlutterError *e) {
         result(e);
     }
  } else if ([@"connect" isEqualToString:call.method]){
      NSDictionary *device = [call arguments];
      @try {
        NSLog(@"connect device begin -> %@", [device objectForKey:@"name"]);
        CBPeripheral *peripheral = [_scannedPeripherals objectForKey:[device objectForKey:@"address"]];
        
        __weak typeof(self) weakSelf = self;
        self.state = ^(ConnectState state) {
            switch (state) {
                case CONNECT_STATE_CONNECTED:
                    result(@(YES));
                    break;
                    
                case CONNECT_STATE_FAILT:
                case CONNECT_STATE_TIMEOUT:
                    result(@(NO));
                    break;
                    
                default:
                    break;
            }
            [weakSelf updateConnectState:state];
        };
        
        [Manager connectPeripheral:peripheral options:nil timeout:2 connectBlack: self.state];
        
      } @catch(FlutterError *e) {
        result(e);
      }
  } else if ([@"disconnect" isEqualToString:call.method]){
      @try {
        [Manager close];
        result(nil);
      } @catch(FlutterError *e) {
        result(e);
      }
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void) startScan {
    [Manager scanForPeripheralsWithServices:nil options:nil discover:^(CBPeripheral * _Nullable peripheral, NSDictionary<NSString *,id> * _Nullable advertisementData, NSNumber * _Nullable RSSI) {
        if (peripheral.name != nil) {
            [self.scannedPeripherals setObject:peripheral forKey:[[peripheral identifier] UUIDString]];
            
            NSDictionary *device = [NSDictionary dictionaryWithObjectsAndKeys:peripheral.identifier.UUIDString,@"address",peripheral.name,@"name",@1,@"type",nil];
            [self->_channel invokeMethod:@"onDiscovered" arguments:device];
        }
    }];
}

-(void)updateConnectState:(ConnectState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber *ret = @0;
        switch (state) {
            case CONNECT_STATE_CONNECTING:
                NSLog(@"status -> %@", @"Connecting ...");
                ret = @0;
                break;
            case CONNECT_STATE_CONNECTED:
                NSLog(@"status -> %@", @"Connection success");
                ret = @1;
                break;
            case CONNECT_STATE_FAILT:
                NSLog(@"status -> %@", @"Connection failed");
                ret = @2;
                break;
            case CONNECT_STATE_DISCONNECT:
                NSLog(@"status -> %@", @"Disconnected");
                ret = @3;
                break;
            default:
                NSLog(@"status -> %@", @"Connection timed out");
                ret = @4;
                break;
        }
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:ret,@"id",nil];
        [self->_channel invokeMethod:@"onStateChanged" arguments:dict];
    });
}

@end
