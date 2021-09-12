import Flutter
import UIKit
import CoreBluetooth

@available(iOS 10.0, *)
public class SwiftFlutterBluetoothPrinterPlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {

    }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "id.flutter.plugins/bluetooth_printer", binaryMessenger: registrar.messenger())
    
    let instance = SwiftFlutterBluetoothPrinterPlugin(methodChannel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    
    
    var centralManager: CBCentralManager? = nil
    var channel: FlutterMethodChannel
    var data: String?
    
    
    var devices: Dictionary<String, BluetoothPeripheral> = [:]
    
    init(methodChannel: FlutterMethodChannel){
        channel = methodChannel
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let method = call.method;
    switch method {
    case "isEnabled":
        let value = centralManager?.state == CBManagerState.poweredOn
        result(value)
        break
        
    case "startScan":
        if (centralManager?.state == CBManagerState.poweredOn && !(centralManager?.isScanning ?? false)){
            centralManager?.scanForPeripherals(withServices: nil)
        }
        
        result(true)
        break
        
    case "stopScan":
        if (centralManager?.isScanning ?? false){
            centralManager?.stopScan()
            devices.removeAll()
        }
        
        result(true)
        break
        
    case "getBondedDevices":
        result([])
        break
        
    case "print":
        let args = call.arguments as! Dictionary<String, Any>
        let uuidString = args["address"] as! String
        let data = args["data"] as! String
        
        let device = self.devices[uuidString];
        if (device != nil){
            self.data = data
            centralManager?.connect(device!.dev)
        }
        break
        
    default:
        result(nil)
    }
  }
    
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
                    let isConnectable = advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber,
                    serviceUUIDs.count > 0, isConnectable == 1 else {
                        return
                }
        
        let peripheralServiceSet = Set(serviceUUIDs.map { $0.uuidString } )
        print(peripheralServiceSet)
        
        let name = peripheral.name ?? ""
        let address = peripheral.identifier.uuidString
        
        let device = BluetoothPeripheral(device: peripheral, name: name as NSString, address: address as NSString, type: 1, services: serviceUUIDs, central: centralManager!)
        devices.updateValue(device, forKey: address)
        
        var dev = Dictionary<String, Any?>()

        dev.updateValue(name as NSString, forKey: "name")
        dev.updateValue(address as NSString, forKey: "address")
        dev.updateValue(1 as NSNumber, forKey: "type")

        channel.invokeMethod("didDiscover", arguments: dev)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let device = self.devices[peripheral.identifier.uuidString];
        if (device != nil){
            device?.dev = peripheral
            device!.print( data: self.data!)
        }
    }
}


public class BluetoothPeripheral: NSObject, CBPeripheralDelegate {
    private let writablecharacteristicUUID = "BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F"
    static var specifiedServices: Set<String> = ["E7810A71-73AE-499D-8C15-FAA9AEF0C3F2"]
    
    var dev: CBPeripheral
    var name: NSString
    var address: NSString
    var type: NSInteger
    var services: [CBUUID]
    var central: CBCentralManager
    
    var data: String = ""
    
    
    init(device: CBPeripheral, name:NSString , address : NSString, type: NSInteger, services: [CBUUID], central: CBCentralManager) {
        self.dev = device
        self.name = name;
        self.address = address;
        self.type = type;
        self.services = services;
        self.central = central;
        
        super.init()
        dev.delegate = self
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }

        guard let prServices = peripheral.services else {
            return
        }

        prServices.filter { BluetoothPeripheral.specifiedServices.contains($0.uuid.uuidString) }.forEach {
            peripheral.discoverCharacteristics(nil, for: $0)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let writablecharacteristic = service.characteristics?.filter { $0.uuid.uuidString == writablecharacteristicUUID }.first
        
        let data = Data(base64Encoded: self.data, options: .ignoreUnknownCharacters)!
        let count = data.count
        if (count < 20){
            peripheral.writeValue(data, for: writablecharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
            return
        }
        
        let dataLen = data.count
        let chunkSize = dev.maximumWriteValueLength(for: CBCharacteristicWriteType.withoutResponse)
        
        let fullChunks = Int(dataLen / chunkSize)
        let totalChunks = fullChunks + (dataLen % chunkSize != 0 ? 1 : 0)

        for chunkCounter in 0..<totalChunks {
          var chunk:Data
          let chunkBase = chunkCounter * chunkSize
          var diff = chunkSize
          if(chunkCounter == totalChunks - 1) {
            diff = dataLen - chunkBase
          }

          let range:Range<Data.Index> = chunkBase..<(chunkBase + diff)
          chunk = data.subdata(in: range)
            peripheral.writeValue(chunk, for: writablecharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        //central.cancelPeripheralConnection(peripheral)
    }
    
    
    public func print(data: String){
        self.data = data
        let serviceUUIDs = BluetoothPeripheral.specifiedServices.map { CBUUID(string: $0) }
        dev.discoverServices(serviceUUIDs)
    }
}
