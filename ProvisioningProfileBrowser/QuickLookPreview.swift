import SwiftUI
import Quartz
import WebKit

struct QuickLookPreview: NSViewRepresentable {
    typealias NSViewType = QLPreviewView

    private let url: URL

    init(url: URL) {
        self.url = url
    }

    func makeNSView(context: Context) -> NSViewType {
        let preview = ProfileQLPreviewView()
        preview.previewItem = url as QLPreviewItem
        return preview
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.previewItem = url as QLPreviewItem
    }
}

class ProfileQLPreviewView: QLPreviewView {
    override var isSelectable: Bool { true }
    override func becomeFirstResponder() -> Bool { true }
}
