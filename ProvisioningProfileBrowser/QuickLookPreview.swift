import SwiftUI
import Quartz

struct QuickLookPreview: NSViewRepresentable {
  typealias NSViewType = ProfilePreviewView

  var url: URL

  func makeNSView(context: Context) -> NSViewType {
    let preview = ProfilePreviewView(frame: .zero, style: .compact)
    preview?.autostarts = true
    preview?.previewItem = url as QLPreviewItem
    return preview ?? ProfilePreviewView(frame: .zero, style: .compact)
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {
    nsView.previewItem = url as QLPreviewItem
  }
}

class ProfilePreviewView: QLPreviewView {
  
}
