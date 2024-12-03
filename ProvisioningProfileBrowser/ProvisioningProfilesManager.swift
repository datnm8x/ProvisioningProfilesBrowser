import Foundation
import Witness
import AppKit

class ProvisioningProfilesManager: ObservableObject {
    @Published var profiles = [ProvisioningProfileModel]() {
        didSet {
            updateVisibleProfiles(query: query)
        }
    }
    @Published var visibleProfiles: [ProvisioningProfileModel] = []
    @Published var loading = false
    @Published var query = "" {
        didSet {
            updateVisibleProfiles(query: query)
        }
    }
    @Published var error: Error?
    
    private var witness: Witness?
    
    init() {
        self.witness = Witness(
            paths: [Self.provisioningProfilesDirectory.path], 
            flags: .FileEvents, 
            latency: 0.3
        ) { [unowned self] events in
            self.reload()
        }
    }
    
    private static var provisioningProfilesDirectory: URL {
        let libraryDirectoryURL = try! FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )

        let xcodeV = Terminal.exeShell("xcodebuild -version").components(separatedBy: "\n").first?.components(separatedBy: " ").last ?? ""
        if xcodeV >= "16.0" {
            return libraryDirectoryURL.appendingPathComponent("Developer/Xcode/UserData").appendingPathComponent("Provisioning Profiles")
        } else {
            return libraryDirectoryURL.appendingPathComponent("MobileDevice").appendingPathComponent("Provisioning Profiles")
        }
    }
    
    func reload() {
        loading = true

        do {
            let enumerator = FileManager.default.enumerator(
                at: Self.provisioningProfilesDirectory,
                includingPropertiesForKeys: [.nameKey],
                options: .skipsHiddenFiles,
                errorHandler: nil
            )!
            
            var profiles = [ProvisioningProfileModel]()
            for case let url as URL in enumerator {
                let profileData = try Data(contentsOf: url)
                let profile = try ProvisioningProfile.parse(from: profileData)

                print("Cers is missing: \(profile.isMissingCers) - \(profile.name)")

                profiles.append(
                    ProvisioningProfileModel(
                        url: url,
                        uuid: profile.uuid,
                        name: profile.name,
                        teamName: profile.teamName,
                        creationDate: profile.creationDate,
                        expirationDate: profile.expirationDate,
                        appID: profile.appID,
                        isMissingCers: profile.isMissingCers,
                        platforms: profile.platforms,
                        cers: profile.developerCertificates.compactMap({ $0.certificate }),
                        entitlements: profile.entitlements.compactMap({
                            guard let value = $0.value.string else { return nil }
                            return Entitlement(key: $0.key, value: value)
                        }),
                        devices: profile.provisionedDevices?.compactMap({ $0.isEmpty ? nil : $0 }) ?? []
                    )
                )
            }

            self.loading = false
            self.profiles = profiles
        } catch {
            self.loading = false
            self.error = error
        }
    }
    
    func delete(profile: ProvisioningProfileModel) {
        do {
            try FileManager.default.trashItem(at: profile.url, resultingItemURL: nil)
            profiles.removeAll { $0 == profile }
        } catch {
            print(error.localizedDescription)
        }
    }

    func revealFinder(profile: ProvisioningProfileModel) {
        NSWorkspace.shared.activateFileViewerSelecting([profile.url])
    }

    private func updateVisibleProfiles(query: String) {
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
}
