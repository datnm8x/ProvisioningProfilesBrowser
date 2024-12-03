//
//  Certificate.swift
//  SwiftyProvisioningProfile
//
//  Created by Sherlock, James on 20/11/2018.
//

import Foundation
import CommonCrypto

public struct Certificate: Encodable, Equatable {

    public enum InitError: Error {
        case failedToFindValue(key: String)
        case failedToCastValue(expected: String, actual: String)
        case failedToFindLabel(label: String)
    }
    
    public let notValidBefore: Date
    public let notValidAfter: Date
    
    public let issuerCommonName: String
    public let issuerCountryName: String
    public let issuerOrgName: String
    public let issuerOrgUnit: String
    
    public let commonName: String?
    public let countryName: String
    public let orgName: String
    public let orgUnit: String
    public let hasPrivateKey: Bool
    public let isInKeyChain: Bool

    public let sha1: String
    public let sha256: String
    public let subjectKeyIdentifier: String
    public let serialNumber: String
    public let signature: String

    init(results: [CFString: Any], commonName: String?, hasPrivateKey: Bool, sha1: Data, sha256: Data) throws {
        self.commonName = commonName
        self.hasPrivateKey = hasPrivateKey
        self.isInKeyChain = Certificate.queryCertificateFromKeyChain(commonName: commonName)
        self.sha1 = sha1.hexDescription
        self.sha256 = sha256.hexDescription

        notValidBefore = try Certificate.getValue(for: kSecOIDX509V1ValidityNotBefore, from: results)
        notValidAfter = try Certificate.getValue(for: kSecOIDX509V1ValidityNotAfter, from: results)
        
        let issuerName: [[CFString: Any]] = try Certificate.getValue(for: kSecOIDX509V1IssuerName, from: results)
        issuerCommonName = try Certificate.getValue(for: kSecOIDCommonName, fromDict: issuerName)
        issuerCountryName = try Certificate.getValue(for: kSecOIDCountryName, fromDict: issuerName)
        issuerOrgName = try Certificate.getValue(for: kSecOIDOrganizationName, fromDict: issuerName)
        issuerOrgUnit = try Certificate.getValue(for: kSecOIDOrganizationalUnitName, fromDict: issuerName)
        
        let subjectName: [[CFString: Any]] = try Certificate.getValue(for: kSecOIDX509V1SubjectName, from: results)
        countryName = try Certificate.getValue(for: kSecOIDCountryName, fromDict: subjectName)
        orgName = try Certificate.getValue(for: kSecOIDOrganizationName, fromDict: subjectName)
        orgUnit = try Certificate.getValue(for: kSecOIDOrganizationalUnitName, fromDict: subjectName)

        subjectKeyIdentifier = try Certificate.getSubjectKeyIdentifier(from: results)
        serialNumber = try Certificate.getValue(for: kSecOIDX509V1SerialNumber, from: results)

        let signatureData: Data = try Certificate.getValue(for: kSecOIDX509V1Signature, from: results)
        signature = signatureData.hexDescription
    }

    static func getValue<T>(for key: CFString, from values: [CFString: Any]) throws -> T {
        let node = values[key] as? [CFString: Any]
        
        guard let rawValue = node?[kSecPropertyKeyValue] else {
            throw InitError.failedToFindValue(key: key as String)
        }
        
        if T.self is Date.Type {
            if let value = rawValue as? TimeInterval {
                // Force unwrap here is fine as we've validated the type above
                return Date(timeIntervalSinceReferenceDate: value) as! T
            }
        }

        guard let value = rawValue as? T else {
            let type = (node?[kSecPropertyKeyType] as? String) ?? String(describing: rawValue)
            throw InitError.failedToCastValue(expected: String(describing: T.self), actual: type)
        }
        
        return value
    }
    
    static func getValue<T>(for key: CFString, fromDict values: [[CFString: Any]]) throws -> T {
        
        guard let results = values.first(where: { ($0[kSecPropertyKeyLabel] as? String) == (key as String) }) else {
            throw InitError.failedToFindLabel(label: key as String)
        }
        
        guard let rawValue = results[kSecPropertyKeyValue] else {
            throw InitError.failedToFindValue(key: key as String)
        }
        
        guard let value = rawValue as? T else {
            let type = (results[kSecPropertyKeyType] as? String) ?? String(describing: rawValue)
            throw InitError.failedToCastValue(expected: String(describing: T.self), actual: type)
        }
        
        return value
    }

    static func getSubjectKeyIdentifier(from values: [CFString: Any]) throws -> String {
        let node = values[kSecOIDSubjectKeyIdentifier] as? [CFString: Any]
        guard let rawValue = node?[kSecPropertyKeyValue], let values = rawValue as? [[CFString : Any]] else {
            throw InitError.failedToFindValue(key: kSecOIDSubjectKeyIdentifier as String)
        }

        guard let rawData = values.first(where: { ($0[kSecPropertyKeyValue] as? Data) != nil })?[kSecPropertyKeyValue] as? Data else {
            throw InitError.failedToFindLabel(label: kSecOIDSubjectKeyIdentifier as String)
        }

        return rawData.hexDescription
    }
}

extension SecCertificate {
    var sha1: Data {
        let derData = data
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        derData.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(derData.count), &digest)
        }
        return Data(digest)
    }

    var sha256: Data {
        let derData = data
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        derData.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(derData.count), &hash)
        }
        return Data(hash)
    }
}

extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: " %02x", $1)}
    }
}
