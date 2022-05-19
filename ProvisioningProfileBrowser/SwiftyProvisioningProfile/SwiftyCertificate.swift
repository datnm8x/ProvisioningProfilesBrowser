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
    
    let commonName = certificate.commonName
    let inKeychain = certificate.inKeychain

    let privateKey = certificate.secIdentity == nil ? false : true
    return try Certificate(results: valuesDict, commonName: commonName as String?, privateKey: privateKey, inKeychain: inKeychain)
  }
  
  private static func getSecCertificate(data: Data) throws -> SecCertificate {
    guard let certificate = SecCertificateCreateWithData(kCFAllocatorDefault, data as CFData) else {
      throw ParseError.failedToCreateCertificate
    }
    
    return certificate
  }
  
}

public extension SecCertificate {
  /**
   * Loads a certificate from a DER encoded file. Wraps `SecCertificateCreateWithData`.
   *
   * - parameter file: The DER encoded file from which to load the certificate
   * - returns: A `SecCertificate` if it could be loaded, or `nil`
   */
  static func create(derEncodedFile file: String) -> SecCertificate? {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: file)) else { return nil }
    let cfData = CFDataCreateWithBytesNoCopy(nil, (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), data.count, kCFAllocatorNull)
    return SecCertificateCreateWithData(kCFAllocatorDefault, cfData!)
  }

  /**
   * Returns the data of the certificate by calling `SecCertificateCopyData`.
   *
   * - returns: the data of the certificate
   */
  var data: Data {
    return SecCertificateCopyData(self) as Data
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
    guard resultCode == errSecSuccess, let trust = uTrust else { return nil }

    return SecTrustCopyKey(trust)
  }

  var serialNumberData: Data? {
    var error: Unmanaged<CFError>?
    let result = SecCertificateCopySerialNumberData(self, &error) as Data?
    if (error != nil) { print(error!) }
    return result
  }

  var secIdentity: SecIdentity? {
    guard let serialNumberData = self.serialNumberData else { return nil }

    let query: [NSString: Any] = [
      kSecClass: kSecClassCertificate,
      kSecAttrSerialNumber: serialNumberData,
      kSecReturnAttributes: kCFBooleanTrue as Any,
      kSecMatchLimit: kSecMatchLimitOne,
      kSecMatchPolicy: SecPolicyCreateBasicX509()
    ]

    var result: CFTypeRef?
    let errNo = SecItemCopyMatching(query as CFDictionary, &result)
    guard errNo == errSecSuccess else { return nil }
    return result as! SecIdentity?
  }

  var commonName: String? {
    var cfCommonName: CFString?
    SecCertificateCopyCommonName(self, &cfCommonName)
    return cfCommonName as String?
  }

  var inKeychain: Bool {
    guard let commonName = commonName as String? else { return false }

    let getquery: [String: Any] = [kSecClass as String: kSecClassCertificate,
                                   kSecAttrLabel as String: commonName,
                                   kSecReturnRef as String: kCFBooleanTrue!]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(getquery as CFDictionary, &item)
    return status == errSecSuccess
  }
}

extension SecIdentity {
  /**
   * Retrieves the identity's private key. Wraps `SecIdentityCopyPrivateKey()`.
   *
   * - returns: the identity's private key, if possible
   */
  public var privateKey: SecKey? {
    var privKey : SecKey?
    guard SecIdentityCopyPrivateKey(self, &privKey) == errSecSuccess else {
      return nil
    }
    return privKey
  }
}

extension SecKey {

  /**
   * Provides the raw key data. Wraps `SecItemCopyMatching()`. Only works if the key is
   * available in the keychain. One common way of using this data is to derive a hash
   * of the key, which then can be used for other purposes.
   *
   * The format of this data is not documented. There's been some reverse-engineering:
   * https://devforums.apple.com/message/32089#32089
   * Apparently it is a DER-formatted sequence of a modulus followed by an exponent.
   * This can be converted to OpenSSL format by wrapping it in some additional DER goop.
   *
   * - returns: the key's raw data if it could be retrieved from the keychain, or `nil`
   */
  public var keyData: Data? {
    return try? getKeyData()
  }

  public func getKeyData() throws -> Data {
    var error: Unmanaged<CFError>?
    guard let data = SecKeyCopyExternalRepresentation(self, &error) as Data? else {
      throw error!.takeRetainedValue() as Error
    }
    return data
  }
}
