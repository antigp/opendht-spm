//
//  File.swift
//  
//
//  Created by Eugene Antropov on 24.02.2023.
//

import Foundation
import opendht_c

public class ValueType: @unchecked Sendable {
    public typealias ID = UInt16
    public init(
        id: ID,
        name: String,
        duration: TimeInterval = 10 * 60,
        storePolicy: ((dht_infohash, Value, dht_infohash, sockaddr) -> Bool)? = nil,
        editPolicy: ((dht_infohash, Value, Value, dht_infohash, sockaddr) -> Bool)? = nil
    ) {
        self.id = id
        self.name = name
        self.duration = duration
        self.storePolicy = storePolicy
        self.editPolicy = editPolicy
    }
    
    public static var USER_DATA: ValueType {
        let userDataPointer = dht_value_type_default_userdata()
        guard let userDataPointer = userDataPointer else { fatalError() }
        return .init(id: dht_get_valuetype_id(userDataPointer), name: String(cString:  dht_get_valuetype_name(userDataPointer)))
    }
    
    public let id: ID
    public let name: String
    public let duration: TimeInterval
    let storePolicy: ((dht_infohash, Value, dht_infohash, sockaddr) -> Bool)?
    let editPolicy: ((dht_infohash, Value, Value, dht_infohash, sockaddr) -> Bool)?
    
    var pointer: OpaquePointer {
        let pointer = Unmanaged.passRetained(self).toOpaque()
        return dht_valuetype_new(id, name.cStringPointer, UInt32(duration), {key, value, hash, addr, addr_len, pointer in
            guard let pointer = pointer, let addr = addr?.pointee, let value = Value(pointer: value) else {
                return false
            }
            let wrapper = Unmanaged<ValueType>.fromOpaque(pointer).takeUnretainedValue()
            return wrapper.storePolicy?(key, value, hash, addr) ?? (value.data.count < 64 * 1024)
        }, {key, old_value, new_value, hash, addr, addr_len, pointer in
            guard let pointer = pointer, let addr = addr?.pointee, let old_value = Value(pointer: old_value), let new_value = Value(pointer: new_value) else {
                return false
            }
            let wrapper = Unmanaged<ValueType>.fromOpaque(pointer).takeUnretainedValue()
            return wrapper.editPolicy?(key, old_value, new_value, hash, addr) ?? false
        }, pointer);
    }
}
