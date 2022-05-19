import Foundation
import CommonCrypto

@objcMembers
class ProvisioningProfile: NSObject {
  var url: URL
  var uuid: String
  var name: String
  var appIdName: String
  var teamName: String
  var teamID: String
  var platforms: [String]
  var creationDate: Date
  var expirationDate: Date
  var applicationID: String?
  var deviceUDIDs: [String]?
  var provisionsAllDevices: Bool
  var getTaskAllow: Bool
  var keychainAccessGroups: [String]
  var certificates: [Certificate]
  var apsEnvironment: String?
  var securityApplicationGroups: [String]

  init(
    url: URL,
    uuid: String,
    name: String,
    appIdName: String,
    teamName: String,
    teamID: String,
    platforms: [String],
    creationDate: Date,
    expirationDate: Date,
    applicationID: String?,
    deviceUDIDs: [String]? = nil,
    provisionsAllDevices: Bool,
    getTaskAllow: Bool,
    keychainAccessGroups: [String],
    certificates: [Certificate],
    apsEnvironment: String?,
    securityApplicationGroups: [String]
  ) {
    self.url = url
    self.uuid = uuid
    self.name = name
    self.appIdName = appIdName
    self.teamName = teamName
    self.teamID = teamID
    self.platforms = platforms
    self.creationDate = creationDate
    self.expirationDate = expirationDate
    self.applicationID = applicationID
    self.deviceUDIDs = deviceUDIDs
    self.provisionsAllDevices = provisionsAllDevices
    self.getTaskAllow = getTaskAllow
    self.keychainAccessGroups = keychainAccessGroups
    self.certificates = certificates
    self.apsEnvironment = apsEnvironment
    self.securityApplicationGroups = securityApplicationGroups
  }
}

extension ProvisioningProfile: Identifiable {
  public var id: String { uuid }
}

extension ProvisioningProfile {
  static func == (lhs: ProvisioningProfile, rhs: ProvisioningProfile) -> Bool {
    lhs.url == rhs.url &&
    lhs.uuid == rhs.uuid &&
    lhs.name == rhs.name &&
    lhs.teamName == rhs.teamName &&
    lhs.creationDate == rhs.creationDate &&
    lhs.expirationDate == rhs.expirationDate
  }

  var fileContents: String? { ProvisioningProfilesManager.getContentsOfProfile(self) }
  var hasDevices: Bool { !(deviceUDIDs ?? []).isEmpty }
  var isEnterprise: Bool { provisionsAllDevices }
}

extension SecCertificate {
  var sha1: Data {
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
    let der = SecCertificateCopyData(self) as Data
    _ = CC_SHA1(Array(der), CC_LONG(der.count), &digest)
    return Data(digest)
  }

  var sha256: Data {
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    let der = SecCertificateCopyData(self) as Data
    _ = CC_SHA256(Array(der), CC_LONG(der.count), &digest)
    return Data(digest)
  }
}
