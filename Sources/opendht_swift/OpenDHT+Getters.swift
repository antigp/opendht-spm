//
//  File.swift
//  
//
//  Created by Eugene Antropov on 01.03.2023.
//

import Foundation
import opendht_c

extension OpenDHT {
    
    private class CResultWrapper: NSObject {
        let yeld: (Value) -> ()
        let finish: (Bool) -> ()
        let filter: (Value) -> Bool
        let limit: Int?
        var received: Int = 0
        init(limit: Int?, yeld: @escaping (Value) -> (), finish: @escaping (Bool) -> (), filter: @escaping (Value) -> Bool) {
            self.limit = limit
            self.yeld = yeld
            self.finish = finish
            self.filter = filter
        }
        
        func handle(response: Value) -> Bool {
            yeld(response)
            received += 1
            if let limit = limit, received >= limit {
                return false
            }
            return true
        }
        
        func finish(success: Bool) {
            finish(success)
        }
        
        func check(object: Value) -> Bool {
           return filter(object)
       }
    }
    
    /// Get values from DHT
    /// id - Hash
    /// limit - Only search for n results
    /// filter - filter recieved data on local client
    /// where - filter on remote client like "id=123 user_type=hello", avaliable props is: id, value_type, owner_pk, user_type
    ///
    public func get(id: InfoHash, limit: Int? = nil, filter: @escaping @Sendable (Value) -> Bool = { _ in true }, where: String = "") async -> AsyncThrowingStream<Value, Error> {
        enum ResultError: Error {
            case unknown
        }
        
        return AsyncThrowingStream<Value, Error> { continuation in
            let wherePointer = ("WHERE " + `where`).cStringPointer
            let wrapper = CResultWrapper(limit: limit, yeld: { value in
                continuation.yield(value)
            }, finish: { success in
                if success {
                    continuation.finish()
                } else {
                    continuation.finish(throwing: ResultError.unknown)
                }
            }, filter: filter)

            let pointer = Unmanaged.passRetained(wrapper).toOpaque()
            //TODO: Remove hash as pointer
            var id = id
            
            dht_runner_get_with_filter(runner, &id, { pointer, swiftObj in
                let value = Value(pointer: pointer)
                if let value = value, let swiftObj = swiftObj {
                    let wrapper = Unmanaged<CResultWrapper>.fromOpaque(swiftObj).takeUnretainedValue()
                    return wrapper.handle(response: value)
                }
                return false
            }, { success, pointer in
                if let pointer = pointer {
                    let wrapper = Unmanaged<CResultWrapper>.fromOpaque(pointer).takeRetainedValue()
                    wrapper.finish(success: success)
                }
            }, pointer, { object, swiftObj in
                if let swiftObj = swiftObj, let value = Value(pointer: object) {
                    let wrapper = Unmanaged<CResultWrapper>.fromOpaque(swiftObj).takeUnretainedValue()
                    return wrapper.check(object: value)
                }
                return false
            }, wherePointer)
        }
    }
    
    func listen(id: InfoHash, limit: Int? = nil, filter: @escaping @Sendable (Value) -> Bool = { _ in true }, where: String = "") async -> AsyncThrowingStream<Value, Error> {
        enum ResultError: Error {
            case unknown
        }
        
        return AsyncThrowingStream<Value, Error> { continuation in
            let wherePointer = ("WHERE " + `where`).cStringPointer
            let wrapper = CResultWrapper(limit: limit, yeld: { value in
                continuation.yield(value)
            }, finish: { success in
                continuation.finish()
            }, filter: filter)

            let pointer = Unmanaged.passRetained(wrapper).toOpaque()
            //TODO: Remove hash as pointer
            var pointerOfId = id
    
            let token = dht_runner_listen_with_filter(runner, &pointerOfId, { pointer, expired, swiftObj in
                let value = Value(pointer: pointer)
                if let value = value, let swiftObj = swiftObj {
                    let wrapper = Unmanaged<CResultWrapper>.fromOpaque(swiftObj).takeUnretainedValue()
                    return wrapper.handle(response: value)
                }
                return false
            }, { pointer in
                if let pointer = pointer {
                    let wrapper = Unmanaged<CResultWrapper>.fromOpaque(pointer).takeRetainedValue()
                    wrapper.finish(success: true)
                }
            }, pointer, { object, swiftObj in
                if let swiftObj = swiftObj, let value = Value(pointer: object) {
                    let wrapper = Unmanaged<CResultWrapper>.fromOpaque(swiftObj).takeUnretainedValue()
                    return wrapper.check(object: value)
                }
                return false
            }, wherePointer)
            
            continuation.onTermination = { @Sendable _ in
                var pointerOfId = id
                dht_runner_cancel_listen(self.runner, &pointerOfId, token)
            }
        }
    }
}
