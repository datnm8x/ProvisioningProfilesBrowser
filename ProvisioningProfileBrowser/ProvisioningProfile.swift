import Foundation

@objcMembers
class ProvisioningProfile: NSObject {
  var url: URL
  var uuid: String
  var name: String
  var appIdName: String
  var teamName: String
  var creationDate: Date
  var expirationDate: Date
  var applicationID: String?
  var deviceUDIDs: [String]?

  init(
    url: URL,
    uuid: String,
    name: String,
    appIdName: String,
    teamName: String,
    creationDate: Date,
    expirationDate: Date,
    applicationID: String?,
    deviceUDIDs: [String]? = nil
  ) {
    self.url = url
    self.uuid = uuid
    self.name = name
    self.appIdName = appIdName
    self.teamName = teamName
    self.creationDate = creationDate
    self.expirationDate = expirationDate
    self.applicationID = applicationID
    self.deviceUDIDs = deviceUDIDs
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
}

