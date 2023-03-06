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
        var closure: (Bool) -> ()
        
        init(closure: @escaping (Bool) -> ()) {
            self.closure = closure
        }
        
        func handle(response: Bool) {
            closure(response)
        }
    }
    
    @discardableResult
    public func put(id: InfoHash, value: Value, permament: Bool = true) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            let value = value.pointer
            
            let wrapper = CResultWrapper { result in
                continuation.resume(returning: result)
            }
            //TODO: Remove hash as pointer
            var id = id
            let pointer = Unmanaged.passRetained(wrapper).toOpaque()
            dht_runner_put(runner, &id, value, { success, pointer in
                if let pointer = pointer {
                    let wrapper = Unmanaged<CResultWrapper>.fromOpaque(pointer).takeRetainedValue()
                    wrapper.handle(response: success)
                }
            }, pointer, permament)
        }
    }
    
    @discardableResult
    public func putEncrypted(id: InfoHash, to: InfoHash, value: Value, permament: Bool = true) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            let value = value.pointer
            
            let wrapper = CResultWrapper { result in
                continuation.resume(returning: result)
            }
            //TODO: Remove hash as pointer
            var id = id
            var to = to
            let pointer = Unmanaged.passRetained(wrapper).toOpaque()
            dht_runner_put_encrypted(runner, &id, &to, value, { success, pointer in
                if let pointer = pointer {
                    let wrapper = Unmanaged<CResultWrapper>.fromOpaque(pointer).takeRetainedValue()
                    wrapper.handle(response: success)
                }
            }, pointer, permament)
        }
    }
    
    @discardableResult
    public func putSigned(id: InfoHash, value: Value, permament: Bool = true) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            let value = value.pointer
            
            let wrapper = CResultWrapper { result in
                continuation.resume(returning: result)
            }
            //TODO: Remove hash as pointer
            var id = id
            let pointer = Unmanaged.passRetained(wrapper).toOpaque()
            dht_runner_put_signed(runner, &id, value, { success, pointer in
                if let pointer = pointer {
                    let wrapper = Unmanaged<CResultWrapper>.fromOpaque(pointer).takeRetainedValue()
                    wrapper.handle(response: success)
                }
            }, pointer, permament)
        }
    }
}
