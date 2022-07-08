#import "FlutterBluetoothPrinterPlugin.h"
#import "ConnecterManager.h"

@interface FlutterBluetoothPrinterPlugin ()
@property(nonatomic, retain) NSObject<FlutterPluginRegistrar> *registrar;
@property(nonatomic, retain) FlutterMethodChannel *channel;
@property(nonatomic, retain) FlutterEventChannel *discoveryChannel;

@property(nonatomic) NSMutableDictionary *eventSinks;
@property(nonatomic) NSMutableDictionary *scannedPeripherals;
@property(nonatomic) NSMutableDictionary *connectedDevices;

@property(nonatomic) bool isAvailable;
@property(nonatomic) bool isInitialized;
@end

@implementation FlutterBluetoothPrinterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"maseka.dev/bluetooth_printer"
            binaryMessenger:[registrar messenger]];
    
    FlutterEventChannel* discoveryChannel = [FlutterEventChannel eventChannelWithName:@"maseka.dev/bluetooth_printer/discovery"
        binaryMessenger:[registrar messenger]];
    
    FlutterBluetoothPrinterPlugin* instance = [[FlutterBluetoothPrinterPlugin alloc] init];
    instance.registrar = registrar;
    instance.channel = channel;
    instance.discoveryChannel = discoveryChannel;
    instance.scannedPeripherals = [NSMutableDictionary new];
    instance.eventSinks = [NSMutableDictionary new];
    instance.connectedDevices = [NSMutableDictionary new];
    
    [registrar addMethodCallDelegate:instance channel:channel];
    [discoveryChannel setStreamHandler:instance];
}

- (instancetype)init
{
    self = [super init];
    return self;
}

- (void) initialize:(void(^)(bool))callback {
    if (self.isAvailable){
        callback(self.isAvailable);
        return;
    }
    
    self.isAvailable = false;
    [Manager didUpdateState:^(NSInteger state) {
        self.isAvailable = false;
        
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
                self.isAvailable = true;
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
      if ([@"connect" isEqualToString:call.method]){
        NSString *address = [call arguments];
        @try {
          CBPeripheral *peripheral = [_scannedPeripherals objectForKey:address];
          FlutterBluetoothDevice *device = [[FlutterBluetoothDevice alloc]
                                            initWithPeripheral:peripheral
                                            binaryMessenger: [self.registrar messenger]
          ];
          
          __weak typeof(self) weakSelf = self;
          self.state = ^(ConnectState state) {
              switch (state) {
                  case CONNECT_STATE_CONNECTED:
                      [weakSelf.connectedDevices setObject:device forKey:device.address];
                      result(@(YES));
                      break;
                      
                  case CONNECT_STATE_DISCONNECT:
                      [weakSelf.connectedDevices removeObjectForKey:device.address];
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
    } else if ([@"dispose" isEqualToString:call.method]){
        [self stopDiscovery];
        result(@(YES));
    } else {
        result(FlutterMethodNotImplemented);
    }
    
  
}

- (void) stopDiscovery {
    [Manager stopScan];
    for (id key in self.connectedDevices){
        CBPeripheral *peripheral = (CBPeripheral*) [self.connectedDevices objectForKey:key];
        [[Manager bleConnecter] closePeripheral: peripheral];
    }
    
    [self.connectedDevices removeAllObjects];
    [self.scannedPeripherals removeAllObjects];
}

- (void) startDiscovery {
    [self initialize:^(bool isAvailable) {
        if (isAvailable){
            [Manager stopScan];
            [self.scannedPeripherals removeAllObjects];
            
            for (id key in self.scannedPeripherals){
                CBPeripheral *peripheral = (CBPeripheral*) [self.scannedPeripherals objectForKey:key];
                NSDictionary *device = [self deviceToMap:peripheral];
                for (id key in self.eventSinks) {
                    FlutterEventSink sink = (FlutterEventSink) [self.eventSinks objectForKey:key];
                    sink(device);
                }
            }
            
            
            [Manager scanForPeripheralsWithServices:nil options:nil discover:^(CBPeripheral * _Nullable peripheral, NSDictionary<NSString *,id> * _Nullable advertisementData, NSNumber * _Nullable RSSI) {
               
                    [self.scannedPeripherals setObject:peripheral forKey:[[peripheral identifier] UUIDString]];
                    
                    NSDictionary *device = [self deviceToMap:peripheral];
                    for (id key in self.eventSinks) {
                        FlutterEventSink sink = (FlutterEventSink) [self.eventSinks objectForKey:key];
                        sink(device);
                    }
                
            }];
        }
    }];
}

- (NSDictionary*) deviceToMap:(CBPeripheral*)peripheral {
    bool isConnected = false;
    
    if ([_connectedDevices objectForKey:peripheral.identifier.UUIDString] != nil){
        isConnected = true;
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

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    FlutterEventSink sink = (FlutterEventSink) [self.eventSinks objectForKey:arguments];
    if (sink != nil){
        [self.eventSinks removeObjectForKey:arguments];
    }

    
    if ([self.eventSinks count] == 0){
        [Manager stopScan];
    }
    
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    [self.eventSinks setObject:events forKey:arguments];
    [self startDiscovery];
    
    return nil;
}

@end


@interface FlutterBluetoothDevice ()
@property(nonatomic) bool isConnected;
@property(nonatomic, retain) FlutterMethodChannel *deviceChannel;
@end

@implementation FlutterBluetoothDevice
- (id) initWithPeripheral:(CBPeripheral*)peripheral
        binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger
{
    if( self = [super init] )
    {
        _address = peripheral.identifier.UUIDString;
        NSString *name = [NSString stringWithFormat:@"%@/%@", @"maseka.dev/bluetooth_printer", _address];
        FlutterMethodChannel *deviceChannel = [FlutterMethodChannel
                             methodChannelWithName:name
                             binaryMessenger:messenger];
        
        _deviceChannel = deviceChannel;
        __weak typeof(self) weakSelf = self;
        [_deviceChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            if ([@"write" isEqualToString:call.method]){
                @try {
                    FlutterStandardTypedData *arg = [call arguments];
                    NSData *data = [arg data];
                    
                    [Manager write:data progress:^(NSUInteger total, NSUInteger progress) {
                        NSDictionary *res = @{@"total": @(total), @"progress": @(progress)};
                        [deviceChannel invokeMethod:@"onPrintingProgress" arguments:res];
                    } receCallBack:^(NSData * _Nullable data) {
                        result(@(YES));
                    }];
               } @catch(FlutterError *e) {
                   result(e);
               }
            } else if ([@"disconnect" isEqualToString:call.method]){
                @try {
                  if (weakSelf.isConnected){
                      [[Manager bleConnecter] closePeripheral:peripheral];
                  }
                  
                  result(@(YES));
                } @catch(FlutterError *e) {
                  result(e);
                }
            }
        }];
    }

    return self;
}


@end
