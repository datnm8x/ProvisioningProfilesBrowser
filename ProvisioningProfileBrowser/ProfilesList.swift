import Foundation
import SwiftUI

struct ProfilesList: NSViewRepresentable {
  typealias NSViewType = NSScrollView

  @Binding private var data: [ProvisioningProfile]
  @Binding var selectedID: ProvisioningProfile.ID?
  @Binding fileprivate var selectionRows: [Int]
  @EnvironmentObject var profilesManager: ProvisioningProfilesManager

  init(data: Binding<[ProvisioningProfile]>, selectedID: Binding<ProvisioningProfile.ID?>, selectionRows: Binding<[Int]>) {
    self._data = data
    self._selectedID = selectedID
    self._selectionRows = selectionRows
  }

  func profile(at: Int) -> ProvisioningProfile? {
    guard at >= 0, at < data.count else { return nil }
    return data[at]
  }

  func profiles(at: [Int]) -> [ProvisioningProfile] {
    at.compactMap({
      guard $0 >= 0, $0 < data.count else { return nil }
      return data[$0]
    })
  }

  func makeNSView(context: Context) -> NSViewType {
    let tableView = TableView()
    tableView.style = .plain
    tableView.usesAlternatingRowBackgroundColors = true
    tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
    tableView.allowsMultipleSelection = true
    tableView.allowsEmptySelection = true

    let columns = [
      configure(NSTableColumn(identifier: .init("icon"))) {
        $0.title = ""
        $0.width = 16
        $0.maxWidth = $0.width
        $0.minWidth = $0.width
      },
      configure(NSTableColumn(identifier: .init("name"))) {
        $0.title = "Name"
        $0.sortDescriptorPrototype = NSSortDescriptor(
          keyPath: \ProvisioningProfile.name,
          ascending: true,
          comparator: { a, b in (a as! String).localizedStandardCompare(b as! String) }
        )
      },
      configure(NSTableColumn(identifier: .init("appid"))) {
        $0.title = "App ID"
        $0.sortDescriptorPrototype = NSSortDescriptor(
          keyPath: \ProvisioningProfile.appIdName,
          ascending: true,
          comparator: { a, b in (a as! String).localizedStandardCompare(b as! String) }
        )
      },
      configure(NSTableColumn(identifier: .init("team"))) {
        $0.title = "Team Name"
        $0.sortDescriptorPrototype = NSSortDescriptor(
          keyPath: \ProvisioningProfile.teamName,
          ascending: true,
          comparator: { a, b in (a as! String).localizedStandardCompare(b as! String) }
        )
      },
      configure(NSTableColumn(identifier: .init("creation"))) {
        $0.title = "Creation Date"
        $0.width = 80
        $0.maxWidth = $0.width
        $0.minWidth = $0.width
        $0.sortDescriptorPrototype = NSSortDescriptor(
          keyPath: \ProvisioningProfile.creationDate,
          ascending: true,
          comparator: { a, b in (a as! Date).compare(b as! Date) }
        )
      },
      configure(NSTableColumn(identifier: .init("expiry"))) {
        $0.title = "Expiry Date"
        $0.width = 80
        $0.maxWidth = $0.width
        $0.minWidth = $0.width
        $0.sortDescriptorPrototype = NSSortDescriptor(
          keyPath: \ProvisioningProfile.expirationDate,
          ascending: true,
          comparator: { a, b in (a as! Date).compare(b as! Date) }
        )
      },
      configure(NSTableColumn(identifier: .init("uuid"))) {
        $0.title = "UUID"
        $0.sortDescriptorPrototype = NSSortDescriptor(
          keyPath: \ProvisioningProfile.uuid,
          ascending: true,
          comparator: { a, b in (a as! String).localizedStandardCompare(b as! String) }
        )
      },
    ]
    columns.forEach(tableView.addTableColumn(_:))
    // Default to sort by name
    tableView.sortDescriptors = [columns.first { $0.identifier.rawValue == "name" }!.sortDescriptorPrototype!]

    tableView.dataSource = context.coordinator
    tableView.delegate = context.coordinator
    tableView.tableViewDelegate = context.coordinator

    let scrollView = NSScrollView()
    scrollView.documentView = tableView
    scrollView.hasVerticalScroller = true

    return scrollView
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {
    context.coordinator.parent = self
    guard let tableView = nsView.subviews[1].subviews.first(where: { ($0 as? NSTableView) != nil }) as? NSTableView else { return }

    context.coordinator.sortByDescriptors(tableView.sortDescriptors)
    tableView.reloadData()

    guard !selectionRows.isEmpty else { return }

    tableView.selectRowIndexes(IndexSet(selectionRows), byExtendingSelection: false)
  }

  // MARK: - Coordinator

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class TableView: NSTableView {
    weak var tableViewDelegate: TableViewDelegate?

    @objc func copySelectedItemInfoToPasteboard() {
      tableViewDelegate?.copySelectedItemInfoToPasteboard(self)
    }

    @objc func tableViewExportSelectedItems() {
      tableViewDelegate?.exportSelectedProfiles(self)
    }

    @objc func tableViewDeleteSelectedItems() {
      tableViewDelegate?.moveSelectedProfilesToTrash(self)
    }

    @objc func tableViewRevealSelectedItemsInFinder() {
      tableViewDelegate?.revealSelectedsInFinder(self)
    }

    @objc func copySelectedDeviceUDIDsToPasteboard() {
      tableViewDelegate?.copyDeviceUDIDsPasteboard(self)
    }

    @objc func copySelectedFileContentsToPasteboard() {
      tableViewDelegate?.copyFileContentsToPasteboard(self)
    }
  }

  class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource, TableViewDelegate {
    var parent: ProfilesList

    init(_ parent: ProfilesList) {
      self.parent = parent
      super.init()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
      parent.data.count
    }

    // MARK: - TableViewDelegate
    func copySelectedItemInfoToPasteboard(_ tableView: NSTableView) {
      guard let profile = parent.profile(at: tableView.selectedRow) else { return }
      let profileInfos = [
        profile.name,
        profile.appIdName,
        profile.teamName,
        Self.dateFormatter.string(from: profile.creationDate),
        Self.dateFormatter.string(from: profile.expirationDate),
        profile.uuid
      ]
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(profileInfos.joined(separator: "   "), forType: .string)
    }

    func exportSelectedProfiles(_ tableView: NSTableView) {
      let profiles = parent.profiles(at: tableView.selectedRowIndexes.indexes)
      guard !profiles.isEmpty else { return }

      parent.profilesManager.exportProfiles(profiles)
    }

    func moveSelectedProfilesToTrash(_ tableView: NSTableView) {
      let profiles = parent.profiles(at: tableView.selectedRowIndexes.indexes)
      guard !profiles.isEmpty else { return }

      parent.profilesManager.delete(profiles: profiles)
    }

    func revealSelectedsInFinder(_ tableView: NSTableView) {
      let profiles = parent.profiles(at: tableView.selectedRowIndexes.indexes)
      guard !profiles.isEmpty else { return }

      parent.profilesManager.revealInFinder(profiles: profiles)
    }

    func copyDeviceUDIDsPasteboard(_ tableView: NSTableView) {
      guard let deviceUDIDs = parent.profile(at: tableView.selectedRow)?.deviceUDIDs else { return }

      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(deviceUDIDs.joined(separator: "\n"), forType: .string)
    }

    func copyFileContentsToPasteboard(_ tableView: NSTableView) {
      guard let fileContents = parent.profile(at: tableView.selectedRow)?.fileContents else { return }

      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      pasteboard.setString(fileContents, forType: .string)
    }

    // MARK: - NSTableViewDelegate
    // MARK: - NSTableViewDataSource

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
      guard let profile = parent.profile(at: row) else { return nil }
      guard let tableColumn = tableColumn else { return nil }

      switch tableColumn.identifier.rawValue {
      case "icon":
        let hostingView = NSHostingView(
          rootView: Image(nsImage: NSWorkspace.shared.icon(forFile: profile.url.path))
            .resizable()
            .frame(width: 16, height: 16)
            .help(profile.url.path)
            .onDrag { NSItemProvider(contentsOf: profile.url)! }
            .onTapGesture(count: 2, perform: { NSWorkspace.shared.activateFileViewerSelecting([profile.url]) })
            .frame(maxWidth: .infinity, alignment: .leading)
        )
        hostingView.identifier = tableColumn.identifier
        return hostingView
      case "name":
        let textField = NSTextField()
        textField.cell = VerticallyCenteredTextFieldCell()
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.stringValue = profile.name
        textField.identifier = tableColumn.identifier
        textField.cell?.truncatesLastVisibleLine = true
        textField.cell?.lineBreakMode = .byTruncatingTail
        textField.textColor = profile.expirationDate < Date() ? .systemRed : .labelColor
        return textField

      case "appid":
        let textField = NSTextField()
        textField.cell = VerticallyCenteredTextFieldCell()
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.stringValue = profile.applicationID ?? profile.appIdName
        textField.identifier = tableColumn.identifier
        textField.cell?.truncatesLastVisibleLine = true
        textField.cell?.lineBreakMode = .byTruncatingTail
        textField.textColor = profile.expirationDate < Date() ? .systemRed : .labelColor
        return textField

      case "team":
        let textField = NSTextField()
        textField.cell = VerticallyCenteredTextFieldCell()
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.stringValue = profile.teamName
        textField.identifier = tableColumn.identifier
        textField.cell?.truncatesLastVisibleLine = true
        textField.cell?.lineBreakMode = .byTruncatingTail
        textField.textColor = profile.expirationDate < Date() ? .systemRed : .labelColor
        return textField

      case "creation":
        let textField = NSTextField()
        textField.cell = VerticallyCenteredTextFieldCell()
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.stringValue = Self.dateFormatter.string(from: profile.creationDate)
        textField.identifier = tableColumn.identifier
        textField.textColor = profile.expirationDate < Date() ? .systemRed : .labelColor
        return textField

      case "expiry":
        let textField = NSTextField()
        textField.cell = VerticallyCenteredTextFieldCell()
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.stringValue = Self.dateFormatter.string(from: profile.expirationDate)
        textField.textColor = profile.expirationDate < Date() ? .systemRed : .labelColor
        textField.identifier = tableColumn.identifier
        return textField
      case "uuid":
        let textField = NSTextField()
        textField.cell = VerticallyCenteredTextFieldCell()
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.stringValue = profile.uuid
        textField.identifier = tableColumn.identifier
        textField.cell?.truncatesLastVisibleLine = true
        textField.cell?.lineBreakMode = .byTruncatingTail
        textField.textColor = profile.expirationDate < Date() ? .systemRed : .labelColor
        return textField

      default:
        fatalError()
      }
    }

    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
      sortByDescriptors(tableView.sortDescriptors)
      tableView.reloadData()
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
      guard let tableView = notification.object as? NSTableView else { return }
      guard tableView.selectedRow > 0 else {
        self.parent.selectionRows = []
        self.parent.selectedID = nil
        return
      }

      let selectedRow = tableView.selectedRow
      var selectedRows = tableView.selectedRowIndexes.indexes
      guard selectedRows != IndexSet(self.parent.selectionRows).indexes else { return }

      DispatchQueue.main.async {
        if let indexSelected = selectedRows.firstIndex(of: selectedRow) {
          selectedRows.remove(at: indexSelected)
        }
        selectedRows.append(selectedRow)
        self.parent.selectionRows = selectedRows
        self.parent.selectedID = self.parent.profile(at: selectedRow)?.id
      }
    }

    func sortByDescriptors(_ sortDescriptors: [NSSortDescriptor]) {
      let elementsAsMutableArray = NSMutableArray(array: parent.data)
      elementsAsMutableArray.sort(using: sortDescriptors)
      if (elementsAsMutableArray as! [ProvisioningProfile]) != parent.data {
        parent.data = elementsAsMutableArray as! [ProvisioningProfile]
      }
    }

    static let dateFormatter = configure(DateFormatter()) {
      $0.dateStyle = .medium
    }
  }
}

class VerticallyCenteredTextFieldCell : NSTextFieldCell {
  override func titleRect(forBounds theRect: NSRect) -> NSRect {
    var titleFrame = super.titleRect(forBounds: theRect)
    let titleSize = self.attributedStringValue.size
    titleFrame.origin.y = theRect.origin.y - 1.0 + (theRect.size.height - titleSize().height) / 2.0
    return titleFrame
  }

  override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
    let titleRect = self.titleRect(forBounds: cellFrame)
    self.attributedStringValue.draw(in: titleRect)
  }
}

protocol TableViewDelegate: AnyObject {
  func copySelectedItemInfoToPasteboard(_ tableView: NSTableView)
  func exportSelectedProfiles(_ tableView: NSTableView)
  func moveSelectedProfilesToTrash(_ tableView: NSTableView)
  func revealSelectedsInFinder(_ tableView: NSTableView)
  func copyDeviceUDIDsPasteboard(_ tableView: NSTableView)
  func copyFileContentsToPasteboard(_ tableView: NSTableView)
}

extension NSTextField {
  open override func performKeyEquivalent(with event: NSEvent) -> Bool {
    guard (self.superview?.superview as? ProfilesList.TableView) != nil else { return false }
    guard event.modifierFlags.contains(NSEvent.ModifierFlags.command) else { return false }
    guard event.type == NSEvent.EventType.keyDown else { return false }
    guard let character = event.charactersIgnoringModifiers else { return false }

    switch character.uppercased() {
    case "C":
      copyItemClicked()
      return true

    case "E":
      exportItemClicked()
      return true

    case "D":
      deleteItemClicked()
      return true

    case "F":
      revealInFinderItemClicked()
      return true

    default:
      return false
    }
  }

  open override func rightMouseDown(with event: NSEvent) {
    let rightMenu = NSMenu()
    rightMenu.addItem(withTitle: "Copy", action: #selector(copyItemClicked(_:)), keyEquivalent: "c")
    rightMenu.addItem(withTitle: "Export", action: #selector(exportItemClicked(_:)), keyEquivalent: "e")
    rightMenu.addItem(withTitle: "Delete", action: #selector(deleteItemClicked(_:)), keyEquivalent: "d")
    rightMenu.addItem(withTitle: "Reveal in Finder", action: #selector(revealInFinderItemClicked(_:)), keyEquivalent: "f")
    rightMenu.addItem(.separator())
    rightMenu.addItem(withTitle: "Copy Device UDIDs", action: #selector(copyDeviceUDIDsClicked(_:)), keyEquivalent: "")
    rightMenu.addItem(withTitle: "Copy File Contents", action: #selector(copyFileContentsClicked(_:)), keyEquivalent: "")
    NSMenu.popUpContextMenu(rightMenu, with: event, for: self)
  }

  @objc private func copyItemClicked(_ sender: AnyObject? = nil) {
//    guard let tblView = self.superview?.superview as? ProfilesList.TableView else { return }
//    tblView.copySelectedItemInfoToPasteboard()
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(self.stringValue, forType: .string)
  }

  @objc private func exportItemClicked(_ sender: AnyObject? = nil) {
    guard let tblView = self.superview?.superview as? ProfilesList.TableView else { return }
    tblView.tableViewExportSelectedItems()
  }

  @objc private func deleteItemClicked(_ sender: AnyObject? = nil) {
    guard let tblView = self.superview?.superview as? ProfilesList.TableView else { return }
    tblView.tableViewDeleteSelectedItems()
  }

  @objc private func revealInFinderItemClicked(_ sender: AnyObject? = nil) {
    guard let tblView = self.superview?.superview as? ProfilesList.TableView else { return }
    tblView.tableViewRevealSelectedItemsInFinder()
  }

  @objc private func copyDeviceUDIDsClicked(_ sender: AnyObject? = nil) {
    guard let tblView = self.superview?.superview as? ProfilesList.TableView else { return }
    tblView.copySelectedDeviceUDIDsToPasteboard()
  }

  @objc private func copyFileContentsClicked(_ sender: AnyObject? = nil) {
    guard let tblView = self.superview?.superview as? ProfilesList.TableView else { return }
    tblView.copySelectedFileContentsToPasteboard()
  }
}

extension NSTableView {
  open override func rightMouseDown(with event: NSEvent) {
    let point = self.convert(event.locationInWindow, from: nil)
    let row = self.row(at: point)
    let col = self.column(at: point)
    guard row >= 0, row < self.numberOfRows, col >= 0, col < self.numberOfColumns else { return }
    guard isRowSelected(row) else { return }
    guard let cellView = self.view(atColumn: col, row: row, makeIfNecessary: false) as? NSTableCellView else { return }

    cellView.textField?.rightMouseDown(with: event)
  }
}
