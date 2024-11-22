import SwiftUI
import Quartz

struct QuickLookPreview: NSViewRepresentable {
    typealias NSViewType = QLPreviewView
    
    private let url: URL

    init(url: URL) {
        self.url = url
    }

    func makeNSView(context: Context) -> NSViewType {
        let preview = ProfileQLPreviewView(frame: .zero, style: .normal)
        preview?.autostarts = true
        preview?.previewItem = url as QLPreviewItem
        return preview ?? ProfileQLPreviewView()
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.previewItem = url as QLPreviewItem
    }
}

class ProfileQLPreviewView: QLPreviewView {
    override var isSelectable: Bool { true }
}
