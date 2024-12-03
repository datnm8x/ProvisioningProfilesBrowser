//
//  SwiftyCertificate.swift
//  SwiftyProvisioningProfile
//
//  Created by Sherlock, James on 20/11/2018.
//

import Foundation
import Security

public extension Certificate {
    
    enum ParseError: Error {
        case failedToCreateCertificate
        case failedToCreateTrust
        case failedToExtractValues
    }
    
    static func parse(from data: Data) throws -> Certificate {
        let certificate = try getSecCertificate(data: data)

        var error: Unmanaged<CFError>?
        let values = SecCertificateCopyValues(certificate, nil, &error)
        
        if let error = error {
            throw error.takeRetainedValue() as Error
        }
        
        guard let valuesDict = values as? [CFString: Any] else {
            throw ParseError.failedToExtractValues
        }
        
        var commonName: CFString?
        SecCertificateCopyCommonName(certificate, &commonName)
        
        return try Certificate(
            results: valuesDict,
            commonName: commonName as String?,
            hasPrivateKey: certificate.clientIdentity?.privateKey != nil,
            sha1: certificate.sha1,
            sha256: certificate.sha256
        )
    }
    
    private static func getSecCertificate(data: Data) throws -> SecCertificate {
        guard let certificate = SecCertificateCreateWithData(kCFAllocatorDefault, data as CFData) else {
            throw ParseError.failedToCreateCertificate
        }
        
        return certificate
    }

    var isMissing: Bool { notValidAfter < .now || notValidBefore > .now || !isInKeyChain || !hasPrivateKey }

    static func queryCertificateFromKeyChain(commonName: String?) -> Bool{
        guard let commonName else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var items: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &items)

        guard status == errSecSuccess, let certificates = items as? [SecCertificate], !certificates.isEmpty else { return false }

        for certificate in certificates {
            var checkCommonName: CFString?
            if SecCertificateCopyCommonName(certificate, &checkCommonName) == errSecSuccess, let cn = checkCommonName as? String, cn == commonName {
                return true
            }
        }
        return false
    }

    static func queryPrivateKey(applicationTag: String) -> SecKey? {
        // Create a query with key type and tag
        let getQuery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: "com.mydomian.uniqueTag",
                                       kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                       kSecReturnRef as String: true]

        // Use this query with the SecItemCopyMatching method to execute a search
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
        guard status == errSecSuccess, let sKey = item else { return nil }
        return (sKey as! SecKey)
    }
}

extension SecIdentity {

    /**
     * Retrieves the identity's private key. Wraps `SecIdentityCopyPrivateKey()`.
     *
     * - returns: the identity's private key, if possible
     */
    var privateKey: SecKey? {
        var privKey : SecKey?
        guard SecIdentityCopyPrivateKey(self, &privKey) == errSecSuccess else {
            return nil
        }
        return privKey
    }

    /**
     * Returns the certificate that belongs to the identity. Wraps `SecIdentityCopyCertificate`.
     *
     * - returns: the certificate, if possible
     */
    var certificate: SecCertificate? {
        var uCert: SecCertificate?
        let status = SecIdentityCopyCertificate(self, &uCert)
        if (status != errSecSuccess) {
            return nil
        }
        return uCert
    }
}

extension SecCertificate {
    /**
     * Returns the data of the certificate by calling `SecCertificateCopyData`.
     *
     * - returns: the data of the certificate
     */
    var data: Data {
        return SecCertificateCopyData(self) as Data
    }

    var clientIdentity: SecIdentity? {
        let getQuery: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecMatchItemList as String: [self],
            kSecReturnRef as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
        guard status == errSecSuccess, let secIdentity = item else { return nil }

        return (secIdentity as! SecIdentity)
    }

    /**
     * Tries to return the public key of this certificate. Wraps `SecTrustCopyPublicKey`.
     * Uses `SecTrustCreateWithCertificates` with `SecPolicyCreateBasicX509()` policy.
     *
     * - returns: the public key if possible
     */
    var publicKey: SecKey? {
        let policy: SecPolicy = SecPolicyCreateBasicX509()
        var uTrust: SecTrust?
        let resultCode = SecTrustCreateWithCertificates([self] as CFArray, policy, &uTrust)
        if (resultCode != errSecSuccess) {
            return nil
        }
        let trust: SecTrust = uTrust!
        return SecTrustCopyKey(trust)
    }
}
