//
//  String+Ex.swift
//  EXViOSBaseExt
//
//  Created by Dat Ng on 15/01/2021.
//  Copyright © 2020 datnm. All rights reserved.
//

import Foundation

public extension String {
  var nsString: NSString { self as NSString }
  var length: Int { nsString.length }
  var trimWhiteSpace: String { trimmingCharacters(in: .whitespaces) }
  var trimWhiteSpaceAndNewLine: String { trimmingCharacters(in: .whitespacesAndNewlines) }
  static let empty: String = ""

  func indexOffset(_ by: Int) -> String.Index {
    index(startIndex, offsetBy: by)
  }

  subscript(index: Int) -> String {
    let indexBy = indexOffset(index)
    guard indexBy < endIndex else { return "" }
    return String(self[indexBy])
  }

  static func path(withComponents components: [String]) -> String {
    NSString.path(withComponents: components)
  }

  func appendingPathComponent(_ pathComponent: String?) -> String {
    guard let pathComponent = pathComponent else {
      return self
    }
    return (self as NSString).appendingPathComponent(pathComponent)
  }

  func appendingPathExtension(_ pathExtension: String?) -> String {
    guard let pathExtension = pathExtension else {
      return self
    }
    return (self as NSString).appendingPathExtension(pathExtension) ?? self
  }

  var pathComponents: [String] { nsString.pathComponents }
  var isAbsolutePath: Bool { nsString.isAbsolutePath }
  var lastPathComponent: String { nsString.lastPathComponent }
  var deletingLastPathComponent: String { nsString.deletingLastPathComponent }
  var pathExtension: String { nsString.pathExtension }
  var deletingPathExtension: String { nsString.deletingPathExtension }

  func indexOf(target: String) -> Int {
    if let range = self.range(of: target) {
      return distance(from: startIndex, to: range.lowerBound)
    }
    return -1
  }

  static func isEmpty(_ string: String?, trimCharacters: CharacterSet = CharacterSet(charactersIn: "")) -> Bool {
    if string == nil { return true }
    return string!.trimmingCharacters(in: trimCharacters) == ""
  }

  func toDate(formatter: DateFormatter) -> Date? {
    formatter.date(from: self)
  }

  func toDate(format dateFormat: String, locale: Locale = .usPOSIX, timeZone: TimeZone? = nil) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat
    dateFormatter.locale = locale
    if let timeZone = timeZone { dateFormatter.timeZone = timeZone }
    return dateFormatter.date(from: self)
  }

  func toDateFormat8601() -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    dateFormatter.locale = Locale.usPOSIX
    return dateFormatter.date(from: self)
  }

  func toDateFormatRFC3339() -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    dateFormatter.locale = Locale.usPOSIX
    return dateFormatter.date(from: self)
  }

  mutating func stringByDeleteCharactersInRange(_ range: NSRange) {
    let startIndex = index(self.startIndex, offsetBy: range.location)
    let endIndex = index(startIndex, offsetBy: range.length)
    removeSubrange(startIndex ..< endIndex)
  }

  func stringByDeletePrefix(_ prefix: String?) -> String {
    if let prefixString = prefix, self.hasPrefix(prefixString) {
      return self.nsString.substring(from: prefixString.length)
    }
    return self
  }

  func stringByDeleteSuffix(_ suffix: String?) -> String {
    if let suffixString = suffix, self.hasSuffix(suffixString) {
      return self.nsString.substring(to: self.length - suffixString.length)
    }
    return self
  }

  func deleteSuffix(_ suffix: Int) -> String {
    if suffix >= length {
      return self
    }
    return nsString.substring(to: length - suffix)
  }

  func deleteSub(_ subStringToDelete: String) -> String {
    replacingOccurrences(of: subStringToDelete, with: "")
  }

  func getRanges(of: String?) -> [NSRange]? {
    guard let ofString = of, String.isEmpty(ofString) == false else {
      return nil
    }

    do {
      let regex = try NSRegularExpression(pattern: ofString)
      return regex.matches(in: self, range: NSRange(location: 0, length: length)).map { (textCheckingResult) -> NSRange in
        textCheckingResult.range
      }
    } catch {
      let range = nsString.range(of: ofString)
      if range.location != NSNotFound {
        var ranges = [NSRange]()
        ranges.append(range)
        let remainString = nsString.substring(from: range.location + range.length)
        if let rangesNext = remainString.getRanges(of: ofString) {
          ranges.append(contentsOf: rangesNext)
        }
        return ranges
      } else {
        return nil
      }
    }
  }

  func rangesOfString(_ ofString: String, options: NSString.CompareOptions = [], searchRange: Range<Index>? = nil) -> [Range<Index>] {
    if let range = self.range(of: ofString, options: options, range: searchRange, locale: nil) {
      let nextRange: Range = range.upperBound ..< endIndex
      return [range] + rangesOfString(ofString, searchRange: nextRange)
    }
    return []
  }

  func addSpaces(_ forMaxLenght: Int) -> String {
    if length >= forMaxLenght { return self }
    var result = self
    for _ in 0 ..< (forMaxLenght - length) {
      result.append(" ")
    }
    return result
  }

  var int: Int? { Int(deleteSub(",")) }
  var int64: Int64? { Int64(deleteSub(",")) }
  var intValue: Int { Int(deleteSub(",")) ?? 0 }
  var int64Value: Int64 { Int64(deleteSub(",")) ?? 0 }

  @discardableResult
  func writeToDocument(_ fileName: String) -> Bool {
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
      let fileURL = dir.appendingPathComponent(fileName)
      // writing
      do {
        try write(to: fileURL, atomically: false, encoding: .utf8)
        return true
      } catch { /* error handling here */ }
    }
    return false
  }

  var isValidPhone: Bool {
    do {
      let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
      let matches = detector.matches(in: self, options: [], range: NSMakeRange(0, count))
      if let res = matches.first {
        return res.resultType == .phoneNumber && res.range.location == 0 && res.range.length == count
      } else {
        return false
      }
    } catch {
      return false
    }
  }

  var isValidUrl: Bool {
    guard let url = URL(string: self) else { return false }
    return !String.isEmpty(url.scheme) && !String.isEmpty(url.host)
  }

  var encodeUrlPercentEncoding: String {
    addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? self
  }

  var localizedString: String {
    NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
  }

  func substring(from: Int) -> String? {
    guard from >= 0 else { return nil }
    return nsString.substring(from: from)
  }

  func substring(to: Int) -> String? {
    guard to >= 0, to < nsString.length else { return nil }
    return nsString.substring(to: to)
  }

  func substring(from: Int, to: Int) -> String? {
    guard from >= 0, to >= 0, to > from, to <= nsString.length else { return nil }
    return nsString.substring(with: NSMakeRange(from, to - from))
  }

  var parseQuery: [String: String] {
    var query = [String: String]()
    let pairs = components(separatedBy: "&")
    for pair in pairs {
      let elements = pair.components(separatedBy: "=")
      if elements.count == 2 {
        let qKey = elements[0].removingPercentEncoding ?? elements[0]
        let qValue = elements[1].removingPercentEncoding ?? elements[1]
        query[qKey] = qValue
      }
    }
    return query
  }

  func encodeUrl(_ characterSet: CharacterSet = .urlFragmentAllowed) -> String {
    addingPercentEncoding(withAllowedCharacters: characterSet) ?? self
  }

  var toURL: URL? { URL(string: trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)) }
  func toURL(trimmingCharacters: CharacterSet = .whitespacesAndNewlines, percentEncoding: CharacterSet? = .urlFragmentAllowed) -> URL? {
    var urlStr = self.trimmingCharacters(in: trimmingCharacters)
    if let percent = percentEncoding { urlStr = urlStr.addingPercentEncoding(withAllowedCharacters: percent) ?? urlStr }
    return URL(string: urlStr)
  }

  var toSelector: Selector { NSSelectorFromString(self) }
  func appendingPathComponentFormat<T: CVarArg>(_ component: T) -> String {
    String(format: self, component)
  }
}

public extension NSMutableAttributedString {
  func addAttribute(_ name: NSAttributedString.Key, value: Any) {
    addAttribute(name, value: value, range: NSRange(location: 0, length: string.length))
  }

  @discardableResult
  func append(_ string: String, attributes: [NSAttributedString.Key: Any]? = nil) -> NSMutableAttributedString {
    append(NSAttributedString(string: string, attributes: attributes))
    return self
  }
}

extension Character {
  /// A simple emoji is one scalar and presented to the user as an Emoji
  var isSimpleEmoji: Bool {
    guard let firstProperties = unicodeScalars.first?.properties else {
      return false
    }
    if #available(iOS 10.2, *) {
      return unicodeScalars.count == 1 && (firstProperties.isEmojiPresentation
        || firstProperties.generalCategory == .otherSymbol)
    } else {
      // Fallback on earlier versions
      for scalar in unicodeScalars {
        switch scalar.value {
        case 0x1F600 ... 0x1F64F, // Emoticons
             0x1F300 ... 0x1F5FF, // Misc Symbols and Pictographs
             0x1F680 ... 0x1F6FF, // Transport and Map
             0x2600 ... 0x26FF, // Misc symbols
             0x2700 ... 0x27BF, // Dingbats
             0xFE00 ... 0xFE0F: // Variation Selectors
          return true
        default:
          continue
        }
      }
      return false
    }
  }

  /// Checks if the scalars will be merged into an emoji
  var isCombinedIntoEmoji: Bool {
    if #available(OSX 10.12.2, iOS 10.2, *) {
      return (unicodeScalars.count > 1 && unicodeScalars.contains { $0.properties.isJoinControl || $0.properties.isVariationSelector })
        || unicodeScalars.allSatisfy { $0.properties.isEmojiPresentation }
    } else {
      // Fallback on earlier versions
      for scalar in unicodeScalars {
        switch scalar.value {
        case 0x1F600 ... 0x1F64F, // Emoticons
             0x1F300 ... 0x1F5FF, // Misc Symbols and Pictographs
             0x1F680 ... 0x1F6FF, // Transport and Map
             0x2600 ... 0x26FF, // Misc symbols
             0x2700 ... 0x27BF, // Dingbats
             0xFE00 ... 0xFE0F: // Variation Selectors
          return true
        default:
          continue
        }
      }
      return false
    }
  }

  var isEmoji: Bool {
    isSimpleEmoji || isCombinedIntoEmoji
  }
}

extension String {
  var isSingleEmoji: Bool {
    count == 1 && containsEmoji
  }

  var containsEmoji: Bool {
    contains { $0.isEmoji }
  }

  var containsOnlyEmoji: Bool {
    !isEmpty && !contains { !$0.isEmoji }
  }

  var emojiString: String {
    emojis.map { String($0) }.reduce("", +)
  }

  var emojis: [Character] {
    filter { $0.isEmoji }
  }

  var emojiScalars: [UnicodeScalar] {
    filter { $0.isEmoji }.flatMap(\.unicodeScalars)
  }
}

public extension URLComponents {
  func queries(lowercaseName: Bool = true) -> [String: String] {
    guard let qis = queryItems else { return [:] }
    var result: [String: String] = [:]
    for qi in qis {
      result[lowercaseName ? qi.name.lowercased() : qi.name] = qi.value ?? ""
    }
    return result
  }
}

public extension URL {
  func queries(componentsResolvingAgainstBaseURL resolve: Bool = false, lowercaseName: Bool = true) -> [String: String] {
    guard let components = URLComponents(url: self, resolvingAgainstBaseURL: resolve) else { return [:] }
    return components.queries(lowercaseName: lowercaseName)
  }

  init?(string: String?, percentEncoding: CharacterSet? = .urlFragmentAllowed) {
    var urlStr = string
    if let percent = percentEncoding { urlStr = string?.addingPercentEncoding(withAllowedCharacters: percent) }
    guard let str = urlStr else { return nil }
    self.init(string: str)
  }
}

public extension URLRequest {
  init(url: URL, headers: [String: String]?) {
    self.init(url: url)
    headers?.forEach { header in
      self.addValue(header.value, forHTTPHeaderField: header.key)
    }
  }
}
