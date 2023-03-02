//
//  File.swift
//  
//
//  Created by Eugene Antropov on 24.02.2023.
//

import Foundation
import opendht_c

public typealias InfoHash = dht_infohash

extension InfoHash {
    static public func from(string: String) -> Self {
        var hash = dht_infohash()
        dht_infohash_get_from_string(&hash, string)
        return hash
    }
    
    static public func from(hex: String) -> Self {
        var hash = dht_infohash()
        dht_infohash_from_hex(&hash, hex)
        return hash
    }
    
    static public func from(data: Data) -> Self {
        var hash = dht_infohash()
        data.withUnsafeBytes { pointer in
            dht_infohash_get(&hash, pointer.baseAddress, pointer.count)
        }
        return hash
    }
    
    static public func random() -> Self {
        var hash = dht_infohash()
        dht_infohash_random(&hash)
        return hash
    }
    
    static public func zero() -> Self {
        var hash = dht_infohash()
        dht_infohash_zero(&hash)
        return hash
    }
}
