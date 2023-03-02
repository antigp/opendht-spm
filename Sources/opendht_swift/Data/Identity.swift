//
//  File.swift
//  
//
//  Created by Eugene Antropov on 02.03.2023.
//

import Foundation
import opendht_c

public typealias Identity = dht_identity

extension Identity {
    static public func empty() -> Self {
        return dht_identity()
    }
    
    static public func load(privateKey: SecKey, certificate: SecCertificate) throws -> Self {
        enum RegisterErrors: Error {
            case failExportPrivKey(String?)
            case failExportCertificate(String?)
        }
        
        var identity = dht_identity()
        var error: Unmanaged<CFError>?
        guard let privateKeyBits = SecKeyCopyExternalRepresentation(privateKey, &error) as Data? else {
            throw RegisterErrors.failExportPrivKey(error?.takeRetainedValue().localizedDescription)
        }
        identity.privatekey = privateKeyBits.withUnsafeBytes { pointer in
            dht_privatekey_import(pointer.baseAddress, pointer.count, nil)
        }
        guard let certificateKeyBits = SecCertificateCopyData(certificate) as Data? else {
            throw RegisterErrors.failExportCertificate(error?.takeRetainedValue().localizedDescription)
        }
        identity.certificate = certificateKeyBits.withUnsafeBytes { pointer in
            dht_certificate_import(pointer.baseAddress, pointer.count)
        }
        return identity
    }
}
