import Foundation
import SwiftUI
import KeyboardShortcuts

struct ProfilesList: NSViewRepresentable {
    typealias NSViewType = NSScrollView

    @Binding var data: [ProvisioningProfileModel]
    @Binding var selection: ProvisioningProfileModel.ID?
    @EnvironmentObject var profilesManager: ProvisioningProfilesManager
    
    init(data: Binding<[ProvisioningProfileModel]>, selection: Binding<ProvisioningProfileModel.ID?>) {
        self._data = data
        self._selection = selection
    }

    func makeNSView(context: Context) -> NSViewType {
        let tableView = TableView()
        tableView.style = .plain
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.selectionHighlightStyle = .regular

        let columns = [
            configure(NSTableColumn(identifier: .init("icon"))) {
                $0.title = ""
                $0.width = 16
            },
            configure(NSTableColumn(identifier: .init("name"))) {
                $0.title = "Name"
                $0.width = 200
                $0.sortDescriptorPrototype = NSSortDescriptor(
                    keyPath: \ProvisioningProfileModel.name,
                    ascending: true,
                    comparator: { a, b in (a as! String).localizedStandardCompare(b as! String) }
                )
            },
            configure(NSTableColumn(identifier: .init("team"))) {
                $0.title = "Team Name"
                $0.sortDescriptorPrototype = NSSortDescriptor(
                    keyPath: \ProvisioningProfileModel.teamName,
                    ascending: true,
                    comparator: { a, b in (a as! String).localizedStandardCompare(b as! String) }
                )
            },
            configure(NSTableColumn(identifier: .init("appid"))) {
                $0.title = "App ID"
                $0.sortDescriptorPrototype = NSSortDescriptor(
                    keyPath: \ProvisioningProfileModel.appID,
                    ascending: true,
                    comparator: { a, b in (a as! String).localizedStandardCompare(b as! String) }
                )
            },
            configure(NSTableColumn(identifier: .init("creation"))) {
                $0.title = "Creation Date"
                $0.sortDescriptorPrototype = NSSortDescriptor(
                    keyPath: \ProvisioningProfileModel.creationDate,
                    ascending: true,
                    comparator: { a, b in (a as! Date).compare(b as! Date) }
                )
            },
            configure(NSTableColumn(identifier: .init("expiry"))) {
                $0.title = "Expiry Date"
                $0.sortDescriptorPrototype = NSSortDescriptor(
                    keyPath: \ProvisioningProfileModel.expirationDate,
                    ascending: true,
                    comparator: { a, b in (a as! Date).compare(b as! Date) }
                )
            },
            configure(NSTableColumn(identifier: .init("uuid"))) {
                $0.title = "UUID"
                $0.sortDescriptorPrototype = NSSortDescriptor(
                    keyPath: \ProvisioningProfileModel.uuid,
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
        tableView.menuItemDelegate = context.coordinator

        let menu = NSMenu()
        let menuItems = [
            NSMenuItem(title: "Copy", action: #selector(TableView.menuCopyItemClicked), keyEquivalent: "c"),
            NSMenuItem(title: "Move to Trash", action: #selector(TableView.menuDeleteItemClicked), keyEquivalent: "d"),
            NSMenuItem(title: "Reveal in Finder", action: #selector(TableView.menuRevealItemClicked), keyEquivalent: "f")
        ]
        menuItems.forEach({
            $0.keyEquivalentModifierMask = .command
            $0.allowsAutomaticKeyEquivalentLocalization = false
            menu.addItem($0)
        })
        tableView.menu = menu
        
        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        
        return scrollView
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        context.coordinator.parent = self
        let tableView = nsView.subviews[1].subviews[0] as! NSTableView
        
        context.coordinator.sortByDescriptors(tableView.sortDescriptors)
        tableView.reloadData()
        
        if let selectedRow = data.firstIndex(where: { $0.id == selection }) {
            tableView.selectRowIndexes(IndexSet([selectedRow]), byExtendingSelection: false)
        }
    }
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class TableView: NSTableView {
        weak var menuItemDelegate: TableViewMenuItemDelegate?

        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            shortkeyAction(event)
        }
    }
    
    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource, TableViewMenuItemDelegate {
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
        func menuItemCopyActionAt(_ row: Int) {
            let profile = parent.data[row]
            let contentCopy = [
                profile.name, profile.teamName,
                Self.dateFormatter.string(from: profile.creationDate),
                Self.dateFormatter.string(from: profile.expirationDate),
                profile.uuid
            ].joined(separator: " ")
            NSPasteboard.general.declareTypes([.string], owner: self)
            NSPasteboard.general.setString(contentCopy, forType: .string)
        }

        func menuItemMoveToTrashAt(_ row: Int) {
            let profile = parent.data[row]
            let alertView = NSAlert()
            alertView.messageText = "Do you want to delete \"\(profile.name)\" provisioning file?"
//            alertView.informativeText = profiles.map({ $0.name }).joined(separator: "\n")
            alertView.addButton(withTitle: "Cancel")
            alertView.addButton(withTitle: "Yes")
            alertView.alertStyle = .warning
            guard alertView.runModal() == .alertSecondButtonReturn else { return }
            parent.profilesManager.delete(profile: profile)
        }

        func menuItemRevealFinderAt(_ row: Int) {
            let profile = parent.data[row]
            parent.profilesManager.revealFinder(profile: profile)
        }

        // MARK: - NSTableViewDelegate
        // MARK: - NSTableViewDataSource
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let profile = parent.data[row]
            
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
                return textField
            case "appid":
                let textField = NSTextField()
                textField.cell = VerticallyCenteredTextFieldCell()
                textField.isEditable = false
                textField.isSelectable = false
                textField.isBezeled = false
                textField.drawsBackground = false
                textField.stringValue = profile.appID
                textField.identifier = tableColumn.identifier
                textField.cell?.truncatesLastVisibleLine = true
                textField.cell?.lineBreakMode = .byTruncatingTail
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
            let row = (notification.object as! NSTableView).selectedRow
            guard row != NSNotFound else { 
                parent.selection = nil
                return
            } 
            let element = parent.data[row]
            
            DispatchQueue.main.async {
                self.parent.selection = element.id
            }
        }

        func sortByDescriptors(_ sortDescriptors: [NSSortDescriptor]) {
            let elementsAsMutableArray = NSMutableArray(array: parent.data)
            elementsAsMutableArray.sort(using: sortDescriptors)
            if (elementsAsMutableArray as! [ProvisioningProfileModel]) != parent.data {
                DispatchQueue.main.async {
                    self.parent.data = elementsAsMutableArray as! [ProvisioningProfileModel]
                }
            }
        }

        static let dateFormatter = configure(DateFormatter()) {
            $0.dateStyle = .medium
        }
    }    
}

class VerticallyCenteredTextFieldCell : NSTextFieldCell {
    private var mIsEditingOrSelecting: Bool = false

    override func drawingRect(forBounds theRect: NSRect) -> NSRect {
        //Get the parent's idea of where we should draw
        var newRect:NSRect = super.drawingRect(forBounds: theRect)

        // When the text field is being edited or selected, we have to turn off the magic because it screws up
        // the configuration of the field editor.  We sneak around this by intercepting selectWithFrame and editWithFrame and sneaking a
        // reduced, centered rect in at the last minute.

        if !mIsEditingOrSelecting {
            // Get our ideal size for current text
            let textSize:NSSize = self.cellSize(forBounds: theRect)

            //Center in the proposed rect
            let heightDelta:CGFloat = newRect.size.height - textSize.height
            if heightDelta > 0 {
                newRect.size.height -= heightDelta
                newRect.origin.y += heightDelta/2
            }
        }

        return newRect
    }

    override func select(withFrame rect: NSRect,
                         in controlView: NSView,
                         editor textObj: NSText,
                         delegate: Any?,
                         start selStart: Int,
                         length selLength: Int)//(var aRect: NSRect, inView controlView: NSView, editor textObj: NSText, delegate anObject: AnyObject?, start selStart: Int, length selLength: Int)
    {
        let arect = self.drawingRect(forBounds: rect)
        mIsEditingOrSelecting = true;
        super.select(withFrame: arect, in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
        mIsEditingOrSelecting = false;
    }

    override func edit(withFrame rect: NSRect,
                       in controlView: NSView,
                       editor textObj: NSText,
                       delegate: Any?,
                       event: NSEvent?)
    {
        let aRect = self.drawingRect(forBounds: rect)
        mIsEditingOrSelecting = true;
        super.edit(withFrame: aRect, in: controlView, editor: textObj, delegate: delegate, event: event)
        mIsEditingOrSelecting = false
    }

    /*
    override func titleRect(forBounds theRect: NSRect) -> NSRect {
        var titleFrame = super.titleRect(forBounds: theRect)
        let titleSize = self.attributedStringValue.size
        titleFrame.origin.y = theRect.origin.y - 1.0 + (theRect.size.height - titleSize().height) / 2.0
        return titleFrame
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        guard !isHighlighted else {
            var dFrame = cellFrame
            dFrame.origin.y += 3.0
            attributedStringValue.draw(in: dFrame)
            return
        }
        let titleRect = self.titleRect(forBounds: cellFrame)
        self.attributedStringValue.draw(in: titleRect)
    }
     */
}

protocol TableViewMenuItemDelegate: AnyObject {
    func menuItemCopyActionAt(_ row: Int)
    func menuItemMoveToTrashAt(_ row: Int)
    func menuItemRevealFinderAt(_ row: Int)
}

// MARK: - Shortcut actions
extension ProfilesList.TableView {

    @objc func menuCopyItemClicked() {
        guard clickedRow >= 0 else { return }
        menuItemDelegate?.menuItemCopyActionAt(clickedRow)
    }

    @objc func menuDeleteItemClicked() {
        guard clickedRow >= 0 else { return }
        menuItemDelegate?.menuItemMoveToTrashAt(clickedRow)
    }

    @objc func menuRevealItemClicked() {
        guard clickedRow >= 0 else { return }
        menuItemDelegate?.menuItemRevealFinderAt(clickedRow)
    }

    func shortkeyAction(_ event: NSEvent) -> Bool {
        guard selectedRow >= 0 else { return false }
        guard event.modifierFlags.contains(NSEvent.ModifierFlags.command) else { return false }
        guard let character = event.charactersIgnoringModifiers else { return false }

        switch character {
        case "c":
            menuItemDelegate?.menuItemCopyActionAt(selectedRow)
            return true

        case "d":
            menuItemDelegate?.menuItemMoveToTrashAt(selectedRow)
            return true

        case "f":
            menuItemDelegate?.menuItemRevealFinderAt(selectedRow)
            return true

        default:
            return false
        }
    }
}
