//
//  ProvisioningPreview.swift
//  ProvisioningProfileBrowser
//
//  Created by Nguyen Mau Dat on 29/11/24.
//

import SwiftUI
import Quartz
import AppKit

struct ProvisioningPreview: NSViewRepresentable {

    typealias NSViewType = NSScrollView

    private weak var profile: ProvisioningProfileModel?

    init(profile: ProvisioningProfileModel?) {
        self.profile = profile
    }

    func makeNSView(context: Context) -> NSScrollView {
        let provisioningPreviewView = ProvisioningPreviewView()
        provisioningPreviewView.register(ProfileDetailItemView.nib, forItemWithIdentifier: ProfileDetailItemView.identifier)
        provisioningPreviewView.register(ProfileDetailHeaderView.nib, forSupplementaryViewOfKind: NSCollectionView.elementKindSectionHeader, withIdentifier: ProfileDetailHeaderView.identifier)
        provisioningPreviewView.register(NSView.classForCoder(), forSupplementaryViewOfKind: NSCollectionView.elementKindSectionFooter, withIdentifier: NSUserInterfaceItemIdentifier("elementKindSectionFooter"))

        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.sectionInset = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        flowLayout.sectionHeadersPinToVisibleBounds = false
        provisioningPreviewView.collectionViewLayout = flowLayout

        let scrollView = NSScrollView()
        scrollView.documentView = provisioningPreviewView
        scrollView.hasVerticalScroller = true
        provisioningPreviewView.dataSource = context.coordinator
        provisioningPreviewView.delegate = context.coordinator

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let previewView = nsView.documentView as? ProvisioningPreviewView else { return }
        context.coordinator.parent = self
        previewView.reloadData()
    }

    // MARK: - Coordinator

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
        enum ProSection: Int, CaseIterable {
            case info, entitlements, certificates, devices

            static func with(_ section: Int) -> Self? {
                .init(rawValue: section)
            }
        }

        var parent: ProvisioningPreview

        init(_ parent: ProvisioningPreview) {
            self.parent = parent
            super.init()
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        private func valueFor(indexPath: IndexPath) -> String? {
            guard let pSection = ProSection.with(indexPath.section), let profile = parent.profile else { return nil }

            switch pSection {
            case .info:
                switch indexPath.item {
                case 0: return profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
                case 1: return profile.appID.trimmingCharacters(in: .whitespacesAndNewlines)
                case 2: return profile.teamName.trimmingCharacters(in: .whitespacesAndNewlines)
                case 3: return profile.platforms.joined(separator: ", ").trimmingCharacters(in: .whitespacesAndNewlines)
                case 4: return profile.teamName.trimmingCharacters(in: .whitespacesAndNewlines)
                case 5: return profile.uuid.trimmingCharacters(in: .whitespacesAndNewlines)
                case 6: return profile.creationDate.formatted().trimmingCharacters(in: .whitespacesAndNewlines)
                case 7: return profile.expirationDate.formatted().trimmingCharacters(in: .whitespacesAndNewlines)
                case 8: return profile.url.lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
                case 9: return profile.url.deletingLastPathComponent().path.trimmingCharacters(in: .whitespacesAndNewlines)
                default: return nil
                }

            case .entitlements: return profile.entitlements[indexPath.item].value.trimmingCharacters(in: .whitespacesAndNewlines)
            case .certificates:
                let cerIndex: Int = indexPath.item / 9
                let indexItem = indexPath.item % 9
                switch indexItem {
                case 0: return profile.certs[cerIndex].commonName?.trimmingCharacters(in: .whitespacesAndNewlines)
                case 1: return profile.certs[cerIndex].notValidAfter.formatted().trimmingCharacters(in: .whitespacesAndNewlines)
                case 2: return profile.certs[cerIndex].sha1.trimmingCharacters(in: .whitespacesAndNewlines)
                case 3: return profile.certs[cerIndex].sha256.trimmingCharacters(in: .whitespacesAndNewlines)
                case 4: return profile.certs[cerIndex].subjectKeyIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
                case 5: return profile.certs[cerIndex].serialNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                case 6: return profile.certs[cerIndex].signature.trimmingCharacters(in: .whitespacesAndNewlines)
                case 7: return profile.certs[cerIndex].isInKeyChain ? "Yes" : "No"
                case 8: return profile.certs[cerIndex].hasPrivateKey ? "Yes" : "No"

                default: return nil
                }

            case .devices: return profile.devices[indexPath.item].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        func numberOfSections(in collectionView: NSCollectionView) -> Int {
            ProSection.allCases.count
        }

        func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
            guard let pSection = ProSection.with(section) else { return 0 }
            guard let profile = parent.profile else { return 0 }

            switch pSection {
            case .info: return 10
            case .entitlements: return profile.entitlements.count
            case .certificates: return profile.certs.count * 9
            case .devices: return profile.devices.count
            }
        }

        func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
            guard kind == NSCollectionView.elementKindSectionHeader else {
                return collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: ProfileDetailHeaderView.identifier, for: indexPath)
            }

            let headerView = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: ProfileDetailHeaderView.identifier, for: indexPath) as! ProfileDetailHeaderView
            headerView.isHiddenSeparator = indexPath.section == 0

            guard let pSection = ProSection.with(indexPath.section) else { return headerView }

            switch pSection {
            case .info:
                headerView.setTitle(parent.profile?.name, alignment: .center)
                headerView.setSubTitle("Expires in \(Int(parent.profile?.expirationDate.timeIntervalSinceNow ?? 0)/86400) days")
            case .entitlements: headerView.setTitle("ENTITLEMENTS")
            case .certificates: headerView.setTitle("CERTIFICATES")
            case .devices: headerView.setTitle("PROVISIONED DEVICES (\(parent.profile?.devices.count ?? 0) DEVICES)")
            }

            return headerView
        }

        func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
            let itemView = collectionView.makeItem(withIdentifier: ProfileDetailItemView.identifier, for: indexPath) as! ProfileDetailItemView

            guard let pSection = ProSection.with(indexPath.section), let profile = parent.profile else { return itemView }

            switch pSection {
            case .info:
                switch indexPath.item {
                case 0: itemView.set(title: "App ID Name", value: valueFor(indexPath: indexPath))
                case 1: itemView.set(title: "App ID", value: valueFor(indexPath: indexPath))
                case 2: itemView.set(title: "Team", value: valueFor(indexPath: indexPath))
                case 3: itemView.set(title: "Platform", value: valueFor(indexPath: indexPath))
                case 4: itemView.set(title: "Type", value: valueFor(indexPath: indexPath))
                case 5: itemView.set(title: "UUID", value: valueFor(indexPath: indexPath))
                case 6: itemView.set(title: "Creation Date", value: valueFor(indexPath: indexPath))
                case 7: itemView.set(title: "Expiration Date", value: valueFor(indexPath: indexPath))
                case 8: itemView.set(title: "File name", value: valueFor(indexPath: indexPath))
                case 9: itemView.set(title: "Path", value: valueFor(indexPath: indexPath))
                default: break
                }

            case .entitlements:
                itemView.set(title: profile.entitlements[indexPath.item].key, value: valueFor(indexPath: indexPath))

            case .certificates:
                let cerIndex: Int = indexPath.item / 9
                let indexItem = indexPath.item % 9
                switch indexItem {
                case 0: itemView.set(title: "Name", value: valueFor(indexPath: indexPath), spacingHidden: indexPath.item == 0)
                case 1: itemView.set(title: "Expiration Date", value: valueFor(indexPath: indexPath))
                case 2: itemView.set(title: "SHA-1", value: valueFor(indexPath: indexPath))
                case 3: itemView.set(title: "SHA-256", value: valueFor(indexPath: indexPath))
                case 4: itemView.set(title: "Subject Key Identifier", value: valueFor(indexPath: indexPath))
                case 5: itemView.set(title: "Serial Number", value: valueFor(indexPath: indexPath))
                case 6: itemView.set(title: "Signature", value: valueFor(indexPath: indexPath))
                case 7: itemView.set(
                    title: "In Keychain", value: valueFor(indexPath: indexPath),
                    color: profile.certs[cerIndex].isInKeyChain ? .labelColor : .red
                )

                case 8: itemView.set(
                    title: "With Private Key", value: valueFor(indexPath: indexPath),
                    color: profile.certs[cerIndex].hasPrivateKey ? .labelColor : .red
                )

                default: break
                }

            case .devices:
                itemView.set(title: "Device ID", value: profile.devices[indexPath.item])
            }

            return itemView
        }

        func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
            let width: CGFloat = CGFloat(Int(collectionView.bounds.width - (1.1 * collectionView.bounds.width)/3 - 78))
            let spacing = (ProSection.with(indexPath.section) == .certificates && indexPath.item % 9 == 0 && indexPath.item != 0) ? 18.0 : 0.0
            return NSSize(width: collectionView.bounds.width, height: ProfileDetailItemView.heightForValue(valueFor(indexPath: indexPath), width: width, spacing: spacing))
        }

        func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
            guard self.collectionView(collectionView, numberOfItemsInSection: section) > 0 else { return .zero }

            if section == 0 {
                return NSSize(width: collectionView.bounds.width, height: 55)
            } else {
                return NSSize(width: collectionView.bounds.width, height: 32)
            }
        }
    }
}

class ProvisioningPreviewView: NSCollectionView {
    convenience init() {
        self.init(frame: .zero)

        NotificationCenter.default.addObserver(self, selector: #selector(didChangePreviewSize), name: NSWindow.didResizeNotification, object: nil)
    }

    @objc private func didChangePreviewSize() {
        collectionViewLayout?.invalidateLayout()
    }
}

class ProfileDetailHeaderView: NSTextField {
    class var identifier: NSUserInterfaceItemIdentifier { NSUserInterfaceItemIdentifier(String(String(describing: Self.self))) }
    class var nib: NSNib? { NSNib(nibNamed: NSNib.Name(String(describing: Self.self)), bundle: nil) }

    @IBOutlet private weak var titleLabel: NSTextField!
    @IBOutlet private weak var subTitleLabel: NSTextField!
    @IBOutlet private weak var separatorLine: NSTextField!

    func setTitle(_ title: String?, alignment: NSTextAlignment = .left) {
        titleLabel.stringValue = title ?? ""
        titleLabel.alignment = alignment
        subTitleLabel.isHidden = true
        if alignment == .center {
            titleLabel.font = .boldSystemFont(ofSize: 21)
        } else {
            titleLabel.font = .boldSystemFont(ofSize: 19)
        }
    }

    func setSubTitle(_ subTitle: String?, alignment: NSTextAlignment = .center) {
        subTitleLabel.stringValue = subTitle ?? ""
        subTitleLabel.alignment = alignment
        subTitleLabel.isHidden = (subTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isHiddenSeparator: Bool {
        get { separatorLine.isHidden }
        set { separatorLine.isHidden = newValue }
    }
}

class ProfileDetailItemView: NSCollectionViewItem {
    @IBOutlet private weak var titleLabel: NSTextField!
    @IBOutlet private weak var valueLabel: NSTextField!
    @IBOutlet private weak var spacingLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        spacingLabel.isHidden = true
        titleLabel.isSelectable = true
        valueLabel.isSelectable = true
    }

    override var title: String? {
        get { titleLabel.stringValue }
        set { titleLabel.stringValue = newValue ?? "" }
    }

    var value: String? {
        get { valueLabel.stringValue }
        set { valueLabel.stringValue = newValue ?? "" }
    }

    func set(title: String?, value: String?, color: NSColor = .labelColor, spacingHidden: Bool = true) {
        self.title = title
        self.value = value
        valueLabel.textColor = color
        spacingLabel.isHidden = spacingHidden
    }

    class func heightForValue(_ value: String?, width: CGFloat, spacing: CGFloat = 0) -> CGFloat {
        guard let value else { return 0 }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15)
        ]
        let attributedText = NSAttributedString(string: value, attributes: attributes)

        let textStorage = NSTextStorage(attributedString: attributedText)
        let textContainer = NSTextContainer(size: NSSize(width: width, height: .greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0
        layoutManager.glyphRange(for: textContainer)

        let sizeText = layoutManager.usedRect(for: textContainer).size
        let textHeight = sizeText.height.rounded(.up) + spacing

        return max(textHeight > 30 ? textHeight + 10 : textHeight, 22)
    }
}

extension NSCollectionViewItem {

    class var identifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier(String(String(describing: Self.self)))
    }

    class var nib: NSNib? {
        NSNib(nibNamed: NSNib.Name(String(describing: Self.self)), bundle: nil)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        textField?.stringValue = ""
    }

    open override func viewWillAppear() {
        super.viewWillAppear()

        textField?.stringValue = ""
    }
}
