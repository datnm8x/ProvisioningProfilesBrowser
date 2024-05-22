import Foundation
import SwiftyProvisioningProfile
import Witness
import AppKit
import UniformTypeIdentifiers

class ProvisioningProfilesManager: ObservableObject {
  @Published var profiles = [ProvisioningProfile]()
  @Published var visibleProfiles: [ProvisioningProfile] = []
  @Published var loading = false
  @Published var query = "" {
    didSet {
      updateVisibleProfiles()
    }
  }
  @Published var error: Error?

  private var witness: Witness?

  init() {
    self.witness = Witness(
      paths: [Self.provisioningProfilesDirectoryURL.path],
      flags: .FileEvents,
      latency: 0.3
    ) { [unowned self] events in
      self.reload()
    }
  }

  private static var provisioningProfilesDirectoryURL: URL {
    let libraryDirectoryURL = try! FileManager.default.url(
      for: .libraryDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: false
    )
    return libraryDirectoryURL.appendingPathComponent("MobileDevice").appendingPathComponent("Provisioning Profiles")
  }

  private static var desktopUrl: URL {
    URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).appendingPathComponent("Desktop")
  }

  func reload() {
    loading = true

    do {
      let enumerator = FileManager.default.enumerator(
        at: Self.provisioningProfilesDirectoryURL,
        includingPropertiesForKeys: [.nameKey],
        options: .skipsHiddenFiles,
        errorHandler: nil
      )!

      var profiles = [ProvisioningProfile]()
      for case let url as URL in enumerator {
        let profileData = try Data(contentsOf: url)
        let profile = try SwiftyProvisioningProfile.ProvisioningProfile.parse(from: profileData)
        profiles.append(profile.toProfile(url: url))
      }

      self.loading = false
      self.profiles = profiles
      self.updateVisibleProfiles()
    } catch {
      self.loading = false
      self.error = error
    }
  }

  func delete(profiles: [ProvisioningProfile]) {
    guard !isAlertEmptySelected(profiles: profiles) else { return }

    let alertView = NSAlert()

    if profiles.count > 1 {
      alertView.messageText = "Do you want to delete these files?"
    } else {
      alertView.messageText = "Do you want to delete the file?"
    }
    alertView.informativeText = profiles.map({ $0.name }).joined(separator: "\n")
    alertView.addButton(withTitle: "Cancel")
    alertView.addButton(withTitle: "Yes")
    alertView.alertStyle = .warning

    guard alertView.runModal() == .alertSecondButtonReturn else { return }

    profiles.forEach { profile in
      do {
        try FileManager.default.trashItem(at: profile.url, resultingItemURL: nil)
        self.profiles.removeAll { $0 == profile }
        self.updateVisibleProfiles()
      } catch {
        print(error.localizedDescription)
      }
    }
  }

  private func updateVisibleProfiles() {
    if query.isEmpty {
      visibleProfiles = profiles
    } else {
      visibleProfiles = profiles.filter {
        $0.name.localizedCaseInsensitiveContains(query) ||
        $0.teamName.localizedCaseInsensitiveContains(query) ||
        $0.uuid.localizedCaseInsensitiveContains(query)
      }
    }
  }

  func revealInFinder(profiles: [ProvisioningProfile]) {
    guard !isAlertEmptySelected(profiles: profiles) else { return }

    NSWorkspace.shared.activateFileViewerSelecting(profiles.map({ $0.url }))
  }

  func exportProfiles(_ profiles: [ProvisioningProfile]) {
    guard !isAlertEmptySelected(profiles: profiles) else { return }

    let savePanel = NSSavePanel()
    savePanel.canCreateDirectories = true
    savePanel.nameFieldStringValue = profiles.map({ $0.name }).joined(separator: ", ")
    savePanel.allowedContentTypes = [UTType(tag: "mobileprovision", tagClass: .filenameExtension, conformingTo: .compositeContent)!]
    savePanel.prompt = "Export"
    savePanel.title = "Export Provisioning Files (replace if exits)"
    savePanel.directoryURL = Self.desktopUrl
    savePanel.begin { (result) in
      guard result == .OK, let saveURL = savePanel.url else { return }
      profiles.forEach {
        FileManager.copyItem(at: $0.url, to: saveURL.appendingPathComponent($0.name + ".mobileprovision"), replaceIfExits: true)
      }
    }
  }

  private func isAlertEmptySelected(profiles: [ProvisioningProfile]) -> Bool {
    guard profiles.isEmpty else { return false }

    let alertView = NSAlert()
    alertView.messageText = "There is no file selected!"
    alertView.addButton(withTitle: "OK")
    alertView.alertStyle = .warning
    alertView.runModal()
    return true
  }
}

extension ProvisioningProfilesManager {
  static func getContentsOfProfile(_ profile: ProvisioningProfile) -> String? {
    guard let profileData = try? Data(contentsOf: profile.url) as NSData, !profileData.isEmpty else { return nil }

    var newDecoder: CMSDecoder?
    CMSDecoderCreate(&newDecoder)

    guard let decoder = newDecoder else { return nil }
    CMSDecoderUpdateMessage(decoder, profileData.bytes, profileData.length)
    CMSDecoderFinalizeMessage(decoder)

    var newData: CFData?
    CMSDecoderCopyContent(decoder, &newData)
    guard let data = newData as Data? else { return nil }

    return String(data: data, encoding: .utf8)
  }
}

extension SwiftyProvisioningProfile.ProvisioningProfile {
  var applicationID: String? {
    guard let result = entitlements["application-identifier"] else { return nil }
    switch result {
    case .string(let value): return value
    default: return nil
    }
  }

  fileprivate func toProfile(url: URL) -> ProvisioningProfile {

    ProvisioningProfile(
      url: url,
      uuid: uuid,
      name: name,
      appIdName: appIdName,
      teamName: teamName,
      creationDate: creationDate,
      expirationDate: expirationDate,
      applicationID: applicationID,
      deviceUDIDs: provisionedDevices
    )
  }
}
