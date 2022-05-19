//
//  Certificate.swift
//  SwiftyProvisioningProfile
//
//  Created by Sherlock, James on 20/11/2018.
//

import Foundation

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
  
  public let commonName: String
  public let countryName: String
  public let orgName: String
  public let orgUnit: String
  public let serialNumber: String
  public let subjectKeyIdentifier: String
  public var sha1: String
  public let sha256: String
  public let signature: String
  public let privateKey: Bool
  public let inKeychain: Bool
  
  init(results: [CFString: Any], commonName: String?, privateKey: Bool, inKeychain: Bool) throws {
    self.commonName = commonName ?? ""

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

    let serialNum: String = try Certificate.getValue(for: kSecOIDX509V1SerialNumber, from: results)
    serialNumber = serialNum
    
    let subjectKeyID: [[CFString: Any]] = try Certificate.getValue(for: kSecOIDSubjectKeyIdentifier, from: results)
    let subjectKeyData: Data = try Certificate.getValue(for: "Key Identifier" as CFString, fromDict: subjectKeyID)
    subjectKeyIdentifier = subjectKeyData.hexDescription(joinedSeparator: " ")

    let fingerprints: [[CFString: Any]] = try Certificate.getValue(for: "Fingerprints" as CFString, from: results)
    let sha1Data: Data = try Certificate.getValue(for: "SHA-1" as CFString, fromDict: fingerprints)
    sha1 = sha1Data.hexDescription
    let sha256Data: Data = try Certificate.getValue(for: "SHA-256" as CFString, fromDict: fingerprints)
    sha256 = sha256Data.hexDescription

    let signatureData: Data = try Certificate.getValue(for: kSecOIDX509V1Signature, from: results)
    signature = signatureData.hexDescription(joinedSeparator: " ")
    self.privateKey = privateKey
    self.inKeychain = inKeychain
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
}

extension Data {
  var hexDescription: String {
    reduce("") { $0 + String(format: "%02x", $1) }
  }

  func hexDescription(joinedSeparator: String) -> String {
    self.map({ String(format: "%02x", $0) }).joined(separator: joinedSeparator)
  }
}
