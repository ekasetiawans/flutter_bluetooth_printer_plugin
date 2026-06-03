import Foundation

public protocol ESCPOSCommandsCreator {

    func data(using encoding: String.Encoding) -> [Data]
}


public struct Receipt: ESCPOSCommandsCreator {
    private let data: Data
    public init(data: Data){
        self.data = data
    }
    
    public func data(using encoding: String.Encoding) -> [Data] {
        return [self.data]
    }
}
