//
//  File.swift
//  
//
//  Created by Eugene Antropov on 21.02.2023.
//

import Foundation
import opendht_c

public struct Value: Sendable {
    public var id: UInt64?
    public var data: Data
    var owner: OpaquePointer?
    public var recipient: dht_infohash?
    public var userType: String?
    public var valueType: ValueType.ID
    
    init?(pointer: OpaquePointer?) {
        id = dht_value_get_id(pointer)
         let dataPointer = dht_value_get_data(pointer)
        if dataPointer.size > 0 {
            data = Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: dataPointer.data), count: dataPointer.size, deallocator: .unmap)
        } else {
            data = Data()
        }
        owner = dht_value_get_owner(pointer)
        recipient = dht_value_get_recipient(pointer)
        valueType = dht_value_get_valuetype_id(pointer)
        guard let userTypePointer = dht_value_get_user_type(pointer) else { return nil }
        userType = String(cString: userTypePointer)
    }
    
    public init(data: Data, valueType: ValueType = .USER_DATA) {
        self.data = data
        self.valueType = valueType.id
    }
    
    var pointer: OpaquePointer {
        let pointer = data.withUnsafeBytes { pointer in
            dht_value_new_with_type(pointer.baseAddress, pointer.count, valueType)
        }
        guard let pointer = pointer else { fatalError("Can't create pointer") }
        if let userType = userType {
            dht_value_set_user_type(pointer, userType.cStringPointer)
        }
        return pointer
    }
}

