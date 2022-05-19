import Foundation

func configure<Subject>(_ subject: Subject, configure: (inout Subject) -> Void) -> Subject {
  var copy = subject
  configure(&copy)
  return copy
}

extension IndexSet {
  var indexes: [Int] { map({ $0 }) }
}

extension FileManager {
  @discardableResult
  static func copyItem(at srcURL: URL, to dstURL: URL, replaceIfExits: Bool = false) -> Error? {
    do {
      if replaceIfExits {
        try self.replaceItemAt(dstURL, withItemAt: srcURL)
      } else {
        try FileManager.default.copyItem(at: srcURL, to: dstURL)
      }
      return nil
    } catch { return error }
  }

  @discardableResult
  static func replaceItemAt(_ originalItemURL: URL, withItemAt newItemURL: URL, backupItemName: String? = nil, options: FileManager.ItemReplacementOptions = []) throws -> URL? {
    try FileManager.default.replaceItemAt(originalItemURL, withItemAt: newItemURL, backupItemName: backupItemName, options: options)
  }
}
