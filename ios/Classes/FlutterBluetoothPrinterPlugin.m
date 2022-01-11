#import "FlutterBluetoothPrinterPlugin.h"
#import "ConnecterManager.h"

@interface FlutterBluetoothPrinterPlugin ()
@property(nonatomic, retain) NSObject<FlutterPluginRegistrar> *registrar;
@property(nonatomic, retain) FlutterMethodChannel *channel;
@property(nonatomic) NSMutableDictionary *scannedPeripherals;
@property(nonatomic) CBPeripheral *connectedDevice;
@property(nonatomic) bool isAvailable;
@property(nonatomic) bool isInitialized;
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

- (instancetype)init
{
    self = [super init];
    return self;
}

- (void) initialize:(void(^)(bool))callback {
    if ([self isInitialized]){
        callback(self.isAvailable);
        return;
    }
    
    self.isAvailable = false;
    [Manager didUpdateState:^(NSInteger state) {
        switch (state) {
            case CBManagerStateUnsupported:
                NSLog(@"The platform/hardware doesn't support Bluetooth Low Energy.");
                callback(false);
                break;
            case CBManagerStateUnauthorized:
                NSLog(@"The app is not authorized to use Bluetooth Low Energy.");
                callback(false);
                break;
            case CBManagerStatePoweredOff:
                NSLog(@"Bluetooth is currently powered off.");
                callback(false);
                break;
            case CBManagerStatePoweredOn:
                self->_isAvailable = true;
                NSLog(@"Bluetooth power on");
                callback(true);
                break;
            case CBManagerStateUnknown:
            default:
                callback(false);
                break;
        }
    }];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"startScan" isEqualToString:call.method]) {
      [self.scannedPeripherals removeAllObjects];
      [self initialize:^(bool isAvailable) {
          if (isAvailable){
              [self startScan];
              result(@(YES));
          } else {
              result(@(NO));
          }
      }];
  } else if ([@"isConnected" isEqualToString:call.method]){
      bool res = [self connectedDevice] != nil;
      result(@(res));
  } else if ([@"connectedDevice" isEqualToString:call.method]){
      if (_connectedDevice != nil){
          NSDictionary *map = [self deviceToMap:_connectedDevice];
          result(map);
          return;
      }
      
      result(nil);
  } else if ([@"stopScan" isEqualToString:call.method]){
      [Manager stopScan];
      result(@(YES));
  } else if ([@"isEnabled" isEqualToString:call.method]){
      [self initialize:^(bool isAvailable) {
          result(@(isAvailable));
      }];
  } else if ([@"print" isEqualToString:call.method]){
      @try {
          FlutterStandardTypedData *arg = [call arguments];
          NSData *data = [arg data];
          
          [Manager write:data progress:^(NSUInteger total, NSUInteger progress) {
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
        CBPeripheral *peripheral = [_scannedPeripherals objectForKey:[device objectForKey:@"address"]];
        
        __weak typeof(self) weakSelf = self;
        self.state = ^(ConnectState state) {
            switch (state) {
                case CONNECT_STATE_CONNECTED:
                    weakSelf.connectedDevice = peripheral;
                    result(@(YES));
                    break;
                    
                case CONNECT_STATE_DISCONNECT:
                    weakSelf.connectedDevice = nil;
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
  } else if ([@"getDevice" isEqualToString:call.method]){
      NSDictionary *device = [call arguments];
      @try {
        CBPeripheral *peripheral = [_scannedPeripherals objectForKey:[device objectForKey:@"address"]];
        if (peripheral != nil){
            NSDictionary *map = [self deviceToMap:peripheral];
            result(map);
        }
      } @catch(FlutterError *e) {
        result(nil);
      }
  } else if ([@"disconnect" isEqualToString:call.method]){
      @try {
        if (_connectedDevice != nil){
            [[Manager bleConnecter] closePeripheral:_connectedDevice];
            _connectedDevice = nil;
        }
        
        result(@(YES));
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
            
            NSDictionary *device = [self deviceToMap:peripheral];
            [self->_channel invokeMethod:@"onDiscovered" arguments:device];
        }
    }];
}

- (NSDictionary*) deviceToMap:(CBPeripheral*)peripheral {
    bool isConnected = false;
    if (_connectedDevice != nil){
        isConnected = _connectedDevice.identifier.UUIDString == peripheral.identifier.UUIDString;
    }
    
    NSDictionary *device = [NSDictionary dictionaryWithObjectsAndKeys:peripheral.identifier.UUIDString,@"address",peripheral.name,@"name",@1,@"type", @(isConnected), @"is_connected",nil];
    return device;
}

-(void)updateConnectState:(ConnectState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber *ret;
        
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
