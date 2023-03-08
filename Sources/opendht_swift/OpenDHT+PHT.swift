//
//  File.swift
//  
//
//  Created by Eugene Antropov on 06.03.2023.
//

import Foundation
import opendht_c

extension OpenDHT {
    public func createPHT(name: String, keys: [String: UInt16]) async -> PHT {
        let string = name.cStringPointer
        var keysInfo = keys.map({ PHTKeySpecValue(key: $0.key.cStringPointer, lenght: Int($0.value)) })
        let spec = keysInfo.withUnsafeMutableBufferPointer { keys in
            PHTKeySpecInfo(items: keys.baseAddress, count: Int32(keys.count))
        }
        let poiter = dht_create_pht(runner, string, spec)
        guard let poiter = poiter else { fatalError() }
        return PHT(phtPointer: poiter)
    }
    
    public func insert(key: [String: Data], value: (InfoHash, ValueType)) async {
        
    }
    
    public func lookup(key: [String: Data], fullMatch: Bool = false) async -> [(InfoHash, ValueType)] {
        return []
    }
}

public class PHT {
    let phtPointer: OpaquePointer
    
    init(phtPointer: OpaquePointer) {
        self.phtPointer = phtPointer
    }
}
