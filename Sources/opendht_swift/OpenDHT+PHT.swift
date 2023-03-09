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
    
  
}

public class PHT {
    private class DoneCResultWrapper: NSObject {
        var closure: (Bool) -> ()
        
        init(closure: @escaping (Bool) -> ()) {
            self.closure = closure
        }
        
        func handle(response: Bool) {
            closure(response)
        }
    }
    
    let phtPointer: OpaquePointer
    
    init(phtPointer: OpaquePointer) {
        self.phtPointer = phtPointer
    }
    
    public func insert(key: [String: Data], value: (InfoHash, Value.ID)) async throws {
        enum InsertError: Error {
            case unknown
        }
        var keysArray: [PHTKeyData] = key.map { (key: String, value: Data) -> PHTKeyData in
            let unsafeRawPointer = UnsafeMutableRawBufferPointer.allocate(byteCount: value.count, alignment: MemoryLayout<UInt8>.alignment)
            [UInt8](value).copyBytes(to: unsafeRawPointer)
            return unsafeRawPointer.withMemoryRebound(to: UInt8.self) { pointer in
                return PHTKeyData(key: key.cStringPointer, data: pointer.baseAddress, dataSize: pointer.count)
            }
        }
        let k = keysArray.withUnsafeMutableBufferPointer { buffer in
            PHTKeyArray(items: buffer.baseAddress, count: Int32(buffer.count))
        }
        
        let value = PHTIndexValue(hash: value.0, objectId: value.1)
        
        try await withCheckedThrowingContinuation { continuation in
            let doneResult = DoneCResultWrapper { success in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(with: .failure(InsertError.unknown))
                }
            }
            let pointer = Unmanaged.passRetained(doneResult).toOpaque()
            pht_insert(phtPointer, k, value, {success, pointer in
                if let pointer = pointer {
                    let wrapper = Unmanaged<DoneCResultWrapper>.fromOpaque(pointer).takeRetainedValue()
                    wrapper.handle(response: success)
                }
            }, pointer)
        }        
    }
    
    public func lookup(key: [String: Data], fullMatch: Bool = false) -> AsyncThrowingStream<(InfoHash, Value.ID), Error> {
        enum LookupError: Error {
            case unknown
        }
        class CResultWrapper: NSObject {
            let yeld: ((InfoHash, Value.ID)) -> ()
            let finish: (Bool) -> ()
            init(yeld: @escaping ((InfoHash, Value.ID)) -> (), finish: @escaping (Bool) -> ()) {
                self.yeld = yeld
                self.finish = finish
            }
            
            func handle(response: (InfoHash, Value.ID)) -> () {
                yeld(response)
            }
            
            func finish(success: Bool) {
                finish(success)
            }
        }
        var keysArray: [PHTKeyData] = key.map { (key: String, value: Data) -> PHTKeyData in
            let unsafeRawPointer = UnsafeMutableRawBufferPointer.allocate(byteCount: value.count, alignment: MemoryLayout<UInt8>.alignment)
            [UInt8](value).copyBytes(to: unsafeRawPointer)
            return unsafeRawPointer.withMemoryRebound(to: UInt8.self) { pointer in
                return PHTKeyData(key: key.cStringPointer, data: pointer.baseAddress, dataSize: pointer.count)
            }
        }
        let k = keysArray.withUnsafeMutableBufferPointer { buffer in
            PHTKeyArray(items: buffer.baseAddress, count: Int32(buffer.count))
        }
        
        return AsyncThrowingStream { continuation in
            let wrapper = CResultWrapper { value in
                continuation.yield(value)
            } finish: { success in
                if success {
                    continuation.finish()
                } else {
                    continuation.finish(throwing: LookupError.unknown)
                }
            }
            let pointer = Unmanaged.passRetained(wrapper).toOpaque()
            pht_lookup(phtPointer, k, {value, pointer in
                if let pointer = pointer {
                    let wrapper = Unmanaged<CResultWrapper>.fromOpaque(pointer).takeUnretainedValue()
                    wrapper.handle(response: (value.hash, value.objectId))
                }
            }, {success, pointer in
                if let pointer = pointer {
                    let wrapper = Unmanaged<CResultWrapper>.fromOpaque(pointer).takeRetainedValue()
                    wrapper.finish(success)
                }
            }, fullMatch, pointer)
        }
    }
}
