//
//  File.swift
//  
//
//  Created by Eugene Antropov on 21.02.2023.
//

import Foundation
import opendht_c

public struct DHTConfig {
    public init(threaded: Bool = true, proxy_server: String? = nil, push_node_id: String? = nil, push_token: String? = nil, push_topic: String? = nil, push_platform: String? = nil, peer_discovery: Bool = true, peer_publish: Bool = true, server_ca: Any? = nil, client_identity: Any? = nil, log: Bool = false) {
        self.threaded = threaded
        self.proxy_server = proxy_server
        self.push_node_id = push_node_id
        self.push_token = push_token
        self.push_topic = push_topic
        self.push_platform = push_platform
        self.peer_discovery = peer_discovery
        self.peer_publish = peer_publish
        self.server_ca = server_ca
        self.client_identity = client_identity
        self.log = log
    }
    
    let threaded: Bool
    let proxy_server: String?
    let push_node_id: String?
    let push_token: String?
    let push_topic: String?
    let push_platform: String?
    let peer_discovery: Bool
    let peer_publish: Bool
    let server_ca: Any?
    let client_identity: Any?
    let log: Bool
}

public actor OpenDHT {
    let runner = dht_runner_new()

    public init(port: Int, config: DHTConfig = DHTConfig()) {
        let secure_config = dht_secure_config()
        let identity = dht_identity()
        let proxy_server_pointer = config.proxy_server?.cStringPointer
        let push_node_id_pointer = config.push_node_id?.cStringPointer
        let push_token_pointer = config.push_token?.cStringPointer
        let push_topic_pointer = config.push_topic?.cStringPointer
        let push_platform_pointer = config.push_platform?.cStringPointer
        var dht_config = dht_runner_config(
            dht_config: secure_config,
            threaded: config.threaded,
            proxy_server: proxy_server_pointer,
            push_node_id: push_node_id_pointer,
            push_token: push_token_pointer,
            push_topic: push_topic_pointer,
            push_platform: push_platform_pointer,
            peer_discovery: config.peer_discovery,
            peer_publish: config.peer_publish,
            server_ca: nil,
            client_identity: identity,
            log: config.log
        )
        dht_runner_run_config(runner, in_port_t(port), &dht_config)
        proxy_server_pointer?.deallocate()
        push_node_id_pointer?.deallocate()
        push_token_pointer?.deallocate()
        push_topic_pointer?.deallocate()
        push_platform_pointer?.deallocate()
    }
    
    public func bootstrap(server: String, port: Int) {
        dht_runner_bootstrap(runner, server, "\(port)")
    }
    
    public func put(id: String, value: Value) async throws -> Bool {
        class CResultWrapper: NSObject {
            var closure: (Bool) -> ()
            
            init(closure: @escaping (Bool) -> ()) {
                self.closure = closure
            }
            
            func handle(response: Bool) {
                closure(response)
            }
        }
        return await withCheckedContinuation { continuation in
            var hash = dht_infohash()
            dht_infohash_get_from_string(&hash, id)
            let value = value.pointer
            
            let wrapper = CResultWrapper { result in
                continuation.resume(returning: result)
            }
            let pointer = Unmanaged.passRetained(wrapper).toOpaque()
            dht_runner_put(runner, &hash, value, { success, pointer in
                if let pointer = pointer {
                    let wrapper = Unmanaged<CResultWrapper>.fromOpaque(pointer).takeRetainedValue()
                    wrapper.handle(response: success)
                }
            }, pointer, true)
        }
    }
    
    
    public func get(id: String, limit: Int? = nil, filter: @escaping @Sendable (Value) -> Bool = { _ in true }) async -> AsyncThrowingStream<Value, Error> {
        class CResultWrapper: NSObject {
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
        enum ResultError: Error {
            case unknown
        }
        
        return AsyncThrowingStream<Value, Error> { continuation in
            var hash = dht_infohash()
            dht_infohash_get_from_string(&hash, id)
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
            dht_runner_get_with_filter(runner, &hash, { pointer, swiftObj in
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
            })
        }
    }
    
    public func register(type: ValueType) {
        dht_register_value_type(runner, type.pointer);
    }
}


extension String {
    var cStringPointer: UnsafeMutablePointer<Int8> {
        return UnsafeMutablePointer(mutating: (self as NSString).utf8String!)
    }
}

