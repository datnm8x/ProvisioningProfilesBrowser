import SwiftUI
import Quartz
import WebKit

struct QuickLookPreview: NSViewRepresentable {
  typealias NSViewType = QLPreviewView

  var url: URL

  func makeNSView(context: Context) -> NSViewType {
    let preview = QLPreviewView(frame: .zero, style: .compact)
    preview?.autostarts = true
    preview?.previewItem = url as QLPreviewItem
    return preview ?? QLPreviewView(frame: .zero, style: .compact)
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {
    nsView.previewItem = url as QLPreviewItem
  }
}

struct ProfilePreviewView: NSViewRepresentable {
  typealias NSViewType = WKWebView

  var htmlString: String

  func makeNSView(context: Context) -> NSViewType {
    let preview = WKWebView()
    preview.loadHTMLString(htmlString, baseURL: nil)
    return preview
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {
    nsView.loadHTMLString(htmlString, baseURL: nil)
  }
}
