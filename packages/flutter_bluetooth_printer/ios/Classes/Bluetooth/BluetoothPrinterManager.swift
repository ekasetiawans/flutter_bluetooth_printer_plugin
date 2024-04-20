import Foundation
import CoreBluetooth

public extension String {
    struct GBEncoding {
        public static let GB_18030_2000 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
    }
}

private extension CBPeripheral {

    var printerState: BluetoothPrinter.State {
        switch state {
        case .disconnected:
            return .disconnected
        case .connected:
            return .connected
        case .connecting:
            return .connecting
        case .disconnecting:
            return .disconnecting
        @unknown default:
            return .disconnected
        }
    }
}

public struct BluetoothPrinter {

    public enum State {

        case disconnected
        case connecting
        case connected
        case disconnecting
    }

    public let name: String?
    public let identifier: UUID

    public var state: State

    public var isConnecting: Bool {
        return state == .connecting
    }

    init(_ peripheral: CBPeripheral) {

        self.name = peripheral.name
        self.identifier = peripheral.identifier
        self.state = peripheral.printerState
    }
}

public enum NearbyPrinterChange {

    case add(BluetoothPrinter)
    case update(BluetoothPrinter)
    case remove(UUID) // identifier
}

public protocol PrinterManagerDelegate: NSObjectProtocol {

    func nearbyPrinterDidChange(_ change: NearbyPrinterChange)
}

public extension BluetoothPrinterManager {

    static var specifiedServices: Set<String> = ["18F0"]
    static var specifiedCharacteristics: Set<String>?
}

public class BluetoothPrinterManager {

    private let queue = DispatchQueue(label: "maseka.dev/flutter_bluetooth_printer")

    private let centralManager: CBCentralManager

    private let centralManagerDelegate = BluetoothCentralManagerDelegate(BluetoothPrinterManager.specifiedServices)
    private let peripheralDelegate = BluetoothPeripheralDelegate(BluetoothPrinterManager.specifiedServices, characteristics: BluetoothPrinterManager.specifiedCharacteristics)

    public weak var delegate: PrinterManagerDelegate?

    public var errorReport: ((PError) -> ())?
    public var didInitialized: ((CBManagerState) -> ())?

    private var connectTimer: Timer?
    
    public var isPermitted: Bool {
        get {
            return centralManager.state != .unauthorized
        }
    }
    
    public var isAvailable: Bool {
        get {
            return centralManager.state == .poweredOn
        }
    }
    

    public var nearbyPrinters: [BluetoothPrinter] {
        return centralManagerDelegate.discoveredPeripherals.values.map { BluetoothPrinter($0) }
    }

    public init(delegate: PrinterManagerDelegate? = nil, didInitialized: ((CBManagerState) -> ())? = nil) {

        centralManager = CBCentralManager(delegate: centralManagerDelegate, queue: queue)

        self.delegate = delegate
        self.didInitialized = didInitialized

        commonInit()
    }

    private func commonInit() {

        peripheralDelegate.wellDoneCanWriteData = { [weak self] in

            self?.connectTimer?.invalidate()
            self?.connectTimer = nil

            self?.nearbyPrinterDidChange(.update(BluetoothPrinter($0)))
            
            self?.didConnected?()
            self?.didConnected = nil
        }

        centralManagerDelegate.peripheralDelegate = peripheralDelegate

        centralManagerDelegate.addedPeripherals = { [weak self] in

            guard let printer = (self?.centralManagerDelegate[$0].map { BluetoothPrinter($0) }) else {
                return
            }
            self?.nearbyPrinterDidChange(.add(printer))
        }

        centralManagerDelegate.updatedPeripherals = { [weak self] in
            guard let printer = (self?.centralManagerDelegate[$0].map { BluetoothPrinter($0) }) else {
                return
            }
            self?.nearbyPrinterDidChange(.update(printer))
        }

        centralManagerDelegate.removedPeripherals = { [weak self] in
            self?.nearbyPrinterDidChange(.remove($0))
        }
        
        
        centralManagerDelegate.centralManagerDidUpdateState = { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.didInitialized?($0.state)
        }

        centralManagerDelegate.centralManagerDidDisConnectPeripheralWithError = { [weak self] _, peripheral, _ in

            guard let `self` = self else {
                return
            }

            self.didConnectError?()
            self.didConnectError = nil
            self.nearbyPrinterDidChange(.update(BluetoothPrinter(peripheral)))
            self.peripheralDelegate.disconnect(peripheral)
        }

        centralManagerDelegate.centralManagerDidFailToConnectPeripheralWithError = { [weak self] _, _, err in

            guard let `self` = self else {
                return
            }

            if let error = err {
                debugPrint(error.localizedDescription)
            }

            self.errorReport?(.connectFailed)
        }
    }

    private func nearbyPrinterDidChange(_ change: NearbyPrinterChange) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.nearbyPrinterDidChange(change)
        }
    }

    private func deliverError(_ error: PError) {
        DispatchQueue.main.async { [weak self] in
            self?.errorReport?(error)
        }
    }

    public func startScan() -> PError? {

        guard !centralManager.isScanning else {
            return nil
        }

        guard centralManager.state == .poweredOn else {
            return .deviceNotReady
        }

        let serviceUUIDs = BluetoothPrinterManager.specifiedServices.map { CBUUID(string: $0) }
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: nil)

        return nil
    }

    public func stopScan() {

        centralManager.stopScan()
    }

    var didConnected: DidConnected?
    var didConnectError: DidConnectError?
    public func connect(_ printer: BluetoothPrinter, didConnected: @escaping DidConnected, didError: @escaping DidConnectError) {
        self.didConnected = didConnected
        self.didConnectError = didError
        
        if (printer.state == .connected){
            didConnected()
            return
        }
        
        guard let per = centralManagerDelegate[printer.identifier] else {

            return
        }

        var p = printer
        p.state = .connecting
        nearbyPrinterDidChange(.update(p))

        if let t = connectTimer {
            t.invalidate()
        }
        connectTimer = Timer(timeInterval: 15, target: self, selector: #selector(connectTimeout(_:)), userInfo: p.identifier, repeats: false)
        RunLoop.main.add(connectTimer!, forMode: .default)

        centralManager.connect(per, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
    }

    @objc private func connectTimeout(_ timer: Timer) {

        guard let uuid = (timer.userInfo as? UUID), let p = centralManagerDelegate[uuid] else {
            return
        }

        var printer = BluetoothPrinter(p)
        printer.state = .disconnected
        nearbyPrinterDidChange(.update(printer))

        centralManager.cancelPeripheralConnection(p)

        connectTimer?.invalidate()
        connectTimer = nil
    }

    public func disconnect(_ printer: BluetoothPrinter) {

        guard let per = centralManagerDelegate[printer.identifier] else {
            return
        }

        var p = printer
        p.state = .disconnecting
        nearbyPrinterDidChange(.update(p))

        centralManager.cancelPeripheralConnection(per)
    }

    public func disconnectAllPrinter() {

        let serviceUUIDs = BluetoothPrinterManager.specifiedServices.map { CBUUID(string: $0) }
        
        centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs).forEach {
            centralManager.cancelPeripheralConnection($0)
        }
    }

    public var canPrint: Bool {
        if peripheralDelegate.writablecharacteristic == nil || peripheralDelegate.writablePeripheral == nil {
            return false
        } else {
            return true
        }
    }

    public func print(_ content: ESCPOSCommandsCreator, encoding: String.Encoding = String.GBEncoding.GB_18030_2000, progressBlock: ((Int, Int) -> ())? = nil, completeBlock: ((PError?) -> ())? = nil) {
            guard let peripheral = self.peripheralDelegate.writablePeripheral, let characteristic = self.peripheralDelegate.writablecharacteristic else {

                completeBlock?(.deviceNotReady)
                return
            }
        
            
            let contentData = content.data(using: encoding)[0]
            let total = contentData.endIndex
            let sendWithoutResponse = characteristic.properties.contains(.writeWithoutResponse)
        
            if (peripheral.canSendWriteWithoutResponse && sendWithoutResponse){
                let chunkSize = peripheral.maximumWriteValueLength(for: .withoutResponse)
                let task = PrintingTask(source: contentData, peripheral: peripheral, characteristic: characteristic, size: chunkSize, type: .withoutResponse)
                var offset = 0
                progressBlock?(0, total)
                
                self.peripheralDelegate.didWriteData = { (peripheral, error) in
                    if error != nil {
                        offset -= chunkSize
                        offset = task.printNext(offset: offset)
                        return
                    }
                    
                    progressBlock?(offset, total)
                    if (offset < total){
                        if (peripheral.canSendWriteWithoutResponse){
                            offset = task.printNext(offset: offset)
                        }
                        return
                    }
                    
                    // Wait for 3 seconds to disconnect the printer automatically
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        completeBlock?(nil)
                        self.peripheralDelegate.didWriteData = nil
                    }
                }
                
                progressBlock?(0, total)
                offset = task.printNext(offset: offset)
                
            } else {
                let chunkSize = peripheral.maximumWriteValueLength(for: .withResponse)
                
                let task = PrintingTask(source: contentData, peripheral: peripheral, characteristic: characteristic, size: chunkSize, type: .withResponse)
                var offset = 0
                
                self.peripheralDelegate.didWriteData = { (peripheral, error) in
                    if error != nil {
                        completeBlock?(.connectFailed)
                        return
                    }
                    
                    progressBlock?(offset, total)
                    if (offset < total){
                        offset = task.printNext(offset: offset)
                        return
                    }
                    
                    // Wait for 3 seconds to disconnect the printer automatically
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        completeBlock?(nil)
                        self.peripheralDelegate.didWriteData = nil
                    }
                }
                
                
                progressBlock?(0, total)
                offset = task.printNext(offset: offset)
            }
        
    }

    deinit {
        connectTimer?.invalidate()
        connectTimer = nil

        disconnectAllPrinter()
    }
}


private struct PrintingTask {
    let source: Data
    let totalLength: Int
    let peripheral: CBPeripheral
    let characteristic: CBCharacteristic
    let max:Int
    let type: CBCharacteristicWriteType
    
    public init(source: Data, peripheral: CBPeripheral, characteristic: CBCharacteristic, size: Int, type: CBCharacteristicWriteType){
        self.peripheral = peripheral
        self.characteristic = characteristic
        self.source = source
        self.totalLength = source.endIndex
        self.max = size
        self.type = type
    }
    
    public func printNext(offset: Int) -> Int {
        var off = offset
        
        let chunkSize = offset + max > totalLength ? totalLength - offset : max
        
        let chunk = source.subdata(in: offset..<offset + chunkSize)
        
        self.peripheral.writeValue(chunk, for: self.characteristic, type: self.type)
        
        
        off += chunkSize
        return off
    }
}
