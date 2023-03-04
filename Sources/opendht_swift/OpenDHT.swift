//
//  File.swift
//  
//
//  Created by Eugene Antropov on 21.02.2023.
//

import Foundation
import opendht_c

public struct DHTConfig {
    public init(threaded: Bool = true, proxy_server: String? = nil, push_node_id: String? = nil, push_token: String? = nil, push_topic: String? = nil, push_platform: String? = nil, peer_discovery: Bool = true, peer_publish: Bool = true, server_ca: SecCertificate? = nil, log: Bool = false) {
        self.threaded = threaded
        self.proxy_server = proxy_server
        self.push_node_id = push_node_id
        self.push_token = push_token
        self.push_topic = push_topic
        self.push_platform = push_platform
        self.peer_discovery = peer_discovery
        self.peer_publish = peer_publish
        self.server_ca = server_ca
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
    let server_ca: SecCertificate?
    let log: Bool
}

public actor OpenDHT {
    let runner = dht_runner_new()

    public init(port: Int, identity: Identity, config: DHTConfig = DHTConfig()) {
        let secure_config = dht_secure_config()        
        let proxy_server_pointer = config.proxy_server?.cStringPointer
        let push_node_id_pointer = config.push_node_id?.cStringPointer
        let push_token_pointer = config.push_token?.cStringPointer
        let push_topic_pointer = config.push_topic?.cStringPointer
        let push_platform_pointer = config.push_platform?.cStringPointer
        var server_ca: OpaquePointer?
        if let server_ca_cert = config.server_ca, let server_ca_data = SecCertificateCopyData(server_ca_cert) as Data? {
            server_ca = server_ca_data.withUnsafeBytes { pointer in
                dht_certificate_import(pointer.baseAddress, pointer.count)
            }
        }
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
            server_ca: server_ca,
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
    
    public func register(type: ValueType) {
        dht_register_value_type(runner, type.pointer);
    }
    
    public func nodeInfo() -> dht_node_info {
        dht_get_node_info(runner)
    }
}


extension String {
    var cStringPointer: UnsafeMutablePointer<Int8> {
        return UnsafeMutablePointer(mutating: (self as NSString).utf8String!)
    }
}

