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
      methodChannelWithName:@"maseka.dev/flutter_bluetooth_printer"
            binaryMessenger:[registrar messenger]];
    
    FlutterEventChannel* discoveryChannel = [FlutterEventChannel eventChannelWithName:@"maseka.dev/flutter_bluetooth_printer/discovery"
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
    if ([@"write" isEqualToString:call.method]){
        NSDictionary *arg = [call arguments];
        NSString *address = arg[@"address"];
        FlutterStandardTypedData *data = arg[@"data"];
        
        // CONNECTING
        [self->_channel invokeMethod:@"didUpdateState" arguments:@(1)];
        
        CBPeripheral *peripheral = [_scannedPeripherals objectForKey:address];
        if (peripheral == nil){
            result(@(NO));
            return;
        }
        
        __block BOOL isPrinted = false;
        [Manager connectPeripheral:peripheral options:nil timeout:2 connectBlack:^(ConnectState state) {
            if (state == CONNECT_STATE_CONNECTED){
                @try {
                    if (isPrinted){
                        return;
                    }
                    
                    isPrinted = true;
                    
                    // PRINTING
                    [self->_channel invokeMethod:@"didUpdateState" arguments:@(2)];
                    
                    [Manager write:[data data] progress:^(NSUInteger total, NSUInteger progress) {
                        NSDictionary *res = @{@"total": @(total), @"progress": @(progress)};
                        [self->_channel invokeMethod:@"onPrintingProgress" arguments:res];
                        
                        if (progress == total){
                            [[Manager bleConnecter] closePeripheral:peripheral];
                            
                            // COMPLETED
                            [self->_channel invokeMethod:@"didUpdateState" arguments:@(3)];
                            
                            // DONE
                            result(@(YES));
                        }
                    } receCallBack:^(NSData * _Nullable data) {
                        
                    }];
                } @catch(FlutterError *e) {
                    result(e);
                }
            }
        }];
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

