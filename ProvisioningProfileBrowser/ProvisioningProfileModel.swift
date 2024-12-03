import Foundation

struct Entitlement {
    let key: String
    let value: String
}

@objcMembers
class ProvisioningProfileModel: NSObject {
    var url: URL
    var uuid: String
    var name: String
    var teamName: String
    var creationDate: Date
    var expirationDate: Date
    var appID: String
    var isMissingCers: Bool
    var platforms: [String]

    var certs: [Certificate]
    var entitlements: [Entitlement]
    var devices: [String]

    init(
        url: URL,
        uuid: String,
        name: String,
        teamName: String,
        creationDate: Date,
        expirationDate: Date,
        appID: String,
        isMissingCers: Bool,
        platforms: [String],
        cers: [Certificate],
        entitlements: [Entitlement],
        devices: [String]
    ) {
        self.url = url
        self.uuid = uuid
        self.name = name
        self.teamName = teamName
        self.creationDate = creationDate
        self.expirationDate = expirationDate
        self.appID = appID
        self.isMissingCers = isMissingCers
        self.platforms = platforms
        self.certs = cers
        self.entitlements = entitlements
        self.devices = devices
    }
}

extension ProvisioningProfileModel: Identifiable {
    public var id: String { uuid }
}

extension ProvisioningProfileModel {
    static func == (lhs: ProvisioningProfileModel, rhs: ProvisioningProfileModel) -> Bool {
        lhs.url == rhs.url &&
            lhs.uuid == rhs.uuid &&
            lhs.name == rhs.name &&
            lhs.teamName == rhs.teamName &&
            lhs.creationDate == rhs.creationDate &&
            lhs.expirationDate == rhs.expirationDate
    }
}
