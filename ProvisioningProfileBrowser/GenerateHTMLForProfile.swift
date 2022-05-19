//
//  GenerateHTMLForProfile.swift
//  ProvisioningProfileBrowser
//
//  Created by Nguyen Mau Dat on 17/05/2022.
//

import Foundation

enum ExpirationStatus {
  case expired
  case expiring
  case valid

  static func withDate(_ date: Date) -> ExpirationStatus {
    let now = Date()
    let dateComponents = Calendar.current.dateComponents([.day], from: now, to: date)
    if date.compare(now) == .orderedAscending { return .expired }
    else if dateComponents.day ?? 0 < 30 { return .expiring }
    else { return .valid }
  }
}

enum GenerateHTMLForProfile {

  private static func formattedGeneralInfo() -> String {
    ""
  }

  private static func formattedExpirationDate(_ dateExpire: Date) -> String {
    let today = Date()
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    formatter.maximumUnitCount = 1
    let dateComponents = Calendar.current.dateComponents([.day, .hour, .minute], from: today, to: dateExpire)
    let days = dateComponents.day ?? 0
    if dateExpire.compare(today) == .orderedAscending {
      if Calendar.current.isDateInToday(dateExpire) {
        return "<span>Expired today</span>"
      } else {
        return "<span>Expired \(days.abs)\(days > 1 ? " days" : "day") ago</span>"
      }
    } else {
      if days == 0 {
        return "<span>Expires today</span>"
      } else if days < 30 {
        return "<span>Expires in \(days.abs)\(days > 1 ? " days" : "day")</span>"
      } else {
        return "Expires in \(days.abs)\(days > 1 ? " days" : "day")"
      }
    }
  }

  private static func formattedDevicesData(_ devices: [String]) -> [String: Any] {
    var devicesHTML = ""
    for device in devices {
      devicesHTML.append("<tr><td class=\"col_left\">Device ID</td><td class=\"col_right\">\(device.uppercased())</td></tr>\n")
    }

    return [
      "ProvisionedDevicesFormatted": devicesHTML,
      "ProvisionedDevicesCount": String(format: "%zd Device%s", devices.count, devices.count == 1 ? "" : "s")
    ]
  }

  static func generateHTMLPreviewForProfile(_ profile: ProvisioningProfile) -> String? {
    guard let htmlURL = Bundle.main.url(forResource: "ProvisioningProfileDetailTemplate", withExtension: "html") else { return nil }
    guard var htmlString = try? String(contentsOf: htmlURL, encoding: .utf8) else { return nil }

    var syncthesizedInfo = [String: String]()

    // Make header info
    syncthesizedInfo["Name"] = profile.name
    syncthesizedInfo["ExpirationDateFormatted"] = profile.expirationDate.toString(format: "d MMM yyyy 'at' HH:mm:ss Z")
    syncthesizedInfo["ExpirationSummary"] = formattedExpirationDate(profile.expirationDate)

    // Make Profile Info
    var generalInfo = ""
    generalInfo.append("<tr><td class=\"col_left\">App ID Name</td><td class=\"col_right\">\(profile.appIdName)</td></tr>\n")
    if let applicationID = profile.applicationID {
      generalInfo.append("<tr><td class=\"col_left\">App ID</td><td class=\"col_right\">\(applicationID)</td></tr>\n")
    }
    generalInfo.append("<tr><td class=\"col_left\">Team</td><td class=\"col_right\">\(profile.teamName)</td></tr>\n")
    generalInfo.append("<tr><td class=\"col_left\">Platform</td><td class=\"col_right\">\(profile.platforms.joined(separator: ", "))</td></tr>\n")

    if (profile.hasDevices) {
      if (profile.getTaskAllow) {
        generalInfo.append("<tr><td class=\"col_left\">Type</td><td class=\"col_right\">Development</td></tr>\n")
      } else {
        generalInfo.append("<tr><td class=\"col_left\">Type</td><td class=\"col_right\">Distribution (Ad Hoc)</td></tr>\n")
      }
    } else {
      if (profile.isEnterprise) {
        generalInfo.append("<tr><td class=\"col_left\">Type</td><td class=\"col_right\">Enterprise</td></tr>\n")
      } else {
        generalInfo.append("<tr><td class=\"col_left\">Type</td><td class=\"col_right\">Distribution (App Store)</td></tr>\n")
      }
    }
    generalInfo.append("<tr><td class=\"col_left\">UUID</td><td class=\"col_right\">\(profile.uuid)</td></tr>\n")
    generalInfo.append("<tr><td class=\"col_left\">Creation Date:</td><td class=\"col_right\">\(profile.creationDate.toString(format: "d MMM yyyy 'at' HH:mm:ss"))</td></tr>\n")
    generalInfo.append("<tr><td class=\"col_left\">Filename</td><td class=\"col_right\">\(profile.url.lastPathComponent)</td></tr>\n")

    syncthesizedInfo["ProvisionGeneralInfoFormatted"] = generalInfo

    // Make Entitlements
    var entitlements = ""
    if let applicationID = profile.applicationID {
      entitlements.append("<tr><td class=\"col_left\">application-identifier</td><td class=\"col_right\">\(String(describing: applicationID))</td></tr>\n")
    }
    if let apsEnvironment = profile.apsEnvironment {
      entitlements.append("<tr><td class=\"col_left\">aps-environment</td><td class=\"col_right\">\(String(describing: apsEnvironment))</td></tr>\n")
    }
    entitlements.append("<tr><td class=\"col_left\">com.apple.developer.team-identifier</td><td class=\"col_right\">\(profile.teamID)</td></tr>\n")
    if !profile.securityApplicationGroups.isEmpty {
      entitlements.append("<tr><td class=\"col_left\">com.apple.security.application-groups</td><td class=\"col_right\">\(profile.securityApplicationGroups.joined(separator: ", "))</td></tr>\n")
    }
    entitlements.append("<tr><td class=\"col_left\">get-task-allow</td><td class=\"col_right\">\(profile.getTaskAllow.yesNoString)</td></tr>\n")
    entitlements.append("<tr><td class=\"col_left\">keychain-access-groups</td><td class=\"col_right\">\(profile.keychainAccessGroups.joined(separator: ", "))</td></tr>\n")
    syncthesizedInfo["EntitlementsFormatted"] = entitlements

    // Make Certificate
    if !profile.certificates.isEmpty {
      var certificates = ""
      for (idx, cer) in profile.certificates.enumerated() {
        if idx > 0 {
          certificates.append("<tr><td class=\"col_left\" style=\"height:20px;\"></td><td class=\"col_right\" style=\"height:20px;\"></td></tr>\n")
        }
        certificates.append("<tr><td class=\"col_left\">Name</td><td class=\"col_right\">\(cer.commonName)</td></tr>\n")
        certificates.append("<tr><td class=\"col_left\">Expiration Date</td><td class=\"col_right\">\(cer.notValidAfter.toString(format: "d MMM yyyy 'at' HH:mm:ss"))</td></tr>\n")
        certificates.append("<tr><td class=\"col_left\">SHA-1</td><td class=\"col_right\">\(cer.sha1)</td></tr>\n")
        certificates.append("<tr><td class=\"col_left\">SHA-256</td><td class=\"col_right\">\(cer.sha256)</td></tr>\n")
        certificates.append("<tr><td class=\"col_left\">Subject Key Identifier</td><td class=\"col_right\">\(cer.subjectKeyIdentifier.uppercased())</td></tr>\n")
        certificates.append("<tr><td class=\"col_left\">Serial Number</td><td class=\"col_right\">\(cer.serialNumber.uppercased())</td></tr>\n")
        certificates.append("<tr><td class=\"col_left\">Signature</td><td class=\"col_right\">\(cer.signature.uppercased())</td></tr>\n")
        certificates.append("<tr><td class=\"col_left\">In Keychain</td><td class=\"col_right\">\(cer.inKeychain.yesNoString)</td></tr>\n")
        certificates.append("<tr><td class=\"col_left\">With Private Key</td><td class=\"col_right\">\(cer.privateKey.yesNoString)</td></tr>\n")
      }
      syncthesizedInfo["DeveloperCertificatesFormatted"] = certificates
    }

    // Make Devices
    if let deviceUDIDs = profile.deviceUDIDs, !deviceUDIDs.isEmpty {
      var devicesFormatted = "<hr></hr>\n"
      devicesFormatted.append("<h2>PROVISIONED DEVICES (\(deviceUDIDs.count) Device\(deviceUDIDs.count == 1 ? "" : "s"))</h2>\n")
      devicesFormatted.append("<table>\n")

      let devices = deviceUDIDs.map({ "<tr><td class=\"col_left\">Device ID</td><td class=\"col_right\">\($0)</td></tr>\n" }).joined(separator: "")

      devicesFormatted.append(devices)
      devicesFormatted.append("</table>\n")
      syncthesizedInfo["ProvisionedDevicesFormatted"] = devicesFormatted
    } else {
      syncthesizedInfo["ProvisionedDevicesFormatted"] = ""
    }

    syncthesizedInfo["BundleShortVersionString"] = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    syncthesizedInfo["BundleVersion"] = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1"

    for syncKey in syncthesizedInfo.keys {
      let replacementValue = syncthesizedInfo[syncKey] ?? ""
      let replacementToken = "__\(syncKey)__"
      htmlString = htmlString.replacingOccurrences(of: replacementToken, with: replacementValue)
    }

    return htmlString
  }
}
