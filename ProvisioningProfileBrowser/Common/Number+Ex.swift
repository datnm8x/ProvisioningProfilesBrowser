//
//  Number+Ex.swift
//  EXViOSBaseExt
//
//  Created by Dat Ng on 15/01/2021.
//  Copyright © 2020 datnm. All rights reserved.
//

import Foundation

public extension SignedNumeric where Self: Comparable {
  var abs: Self { Swift.abs(self) }
}

public extension SignedInteger where Self: FixedWidthInteger {
  func toValue<T: BinaryFloatingPoint>() -> T {
    T(self)
  }
  
  func toValue<T: SignedNumeric>() -> T where T: FixedWidthInteger {
    T(self)
  }
}

public extension SignedNumeric where Self: LosslessStringConvertible {
  func toString(style: NumberFormatter.Style = .decimal,
                groupSeparator: String? = nil,
                decimalSeparator: String? = nil,
                minFractionDigits: Int? = nil,
                maxFractionDigits: Int? = nil,
                locale: Locale? = nil) -> String
  {
  let format = NumberFormatter()
  format.numberStyle = style
  if let gSeparator = groupSeparator {
    format.groupingSeparator = gSeparator
    format.usesGroupingSeparator = true
  }
  if let dSeparator = decimalSeparator { format.decimalSeparator = dSeparator }
  if let min = minFractionDigits { format.minimumFractionDigits = min }
  if let max = maxFractionDigits { format.maximumFractionDigits = max }
  if let locale = locale { format.locale = locale }
  
  return format.string(for: self) ?? String(self)
  }
}

public extension BinaryFloatingPoint {
  var abs: Self { Swift.abs(self) }
  
  func toValue<T: BinaryFloatingPoint>() -> T {
    T(self)
  }
  
  func toValue<T: SignedNumeric>() -> T where T: FixedWidthInteger {
    T(self)
  }
}

public extension BinaryFloatingPoint where Self: LosslessStringConvertible {
  func toString(style: NumberFormatter.Style = .decimal,
                groupSeparator: String? = nil,
                decimalSeparator: String? = nil,
                minFractionDigits: Int? = nil,
                maxFractionDigits: Int? = nil,
                locale: Locale? = nil) -> String
  {
  let format = NumberFormatter()
  format.numberStyle = style
  if let gSeparator = groupSeparator {
    format.groupingSeparator = gSeparator
    format.usesGroupingSeparator = true
  }
  if let dSeparator = decimalSeparator { format.decimalSeparator = dSeparator }
  if let min = minFractionDigits { format.minimumFractionDigits = min }
  if let max = maxFractionDigits { format.maximumFractionDigits = max }
  if let locale = locale { format.locale = locale }
  
  return format.string(for: self) ?? String(self)
  }
}

public extension Int {
  var int64Value: Int64 { Int64(self) }
  var number: NSNumber { NSNumber(value: self) }
  var cgFloat: CGFloat { toValue() }
}

public extension Int64 {
  var intValue: Int { Int(self) }
  var number: NSNumber { NSNumber(value: self) }
  var cgFloat: CGFloat { toValue() }
}

public extension Float {
  var intValue: Int { toValue() }
}

public extension CGFloat {
  var intValue: Int { toValue() }
}

public extension NSEdgeInsets {
  var inverted: NSEdgeInsets {
    NSEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
  }
  
  static func with(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> NSEdgeInsets {
    NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)
  }
  
  func with(top: CGFloat? = nil, left: CGFloat? = nil, bottom: CGFloat? = nil, right: CGFloat? = nil) -> NSEdgeInsets {
    var newInsets = self
    if let nTop = top { newInsets.top = nTop }
    if let nLeft = left { newInsets.left = nLeft }
    if let nBottom = bottom { newInsets.bottom = nBottom }
    if let nRight = right { newInsets.right = nRight }
    return newInsets
  }
}

public extension CGSize {
  static func square(_ size: CGFloat) -> CGSize { CGSize(width: size, height: size) }
}

extension CGRect {
  var center: CGPoint {
    CGPoint(x: midX, y: midY)
  }
  
  func edgeInsetted(_ insets: NSEdgeInsets) -> CGRect {
    var copy = self
    copy.edgeInset(insets)
    return copy
  }
  
  mutating func edgeInset(_ insets: NSEdgeInsets) {
    origin.x += insets.left
    origin.y += insets.top
    size.width -= (insets.left + insets.right)
    size.height -= (insets.top + insets.bottom)
  }
  
  func expanded(_ add: CGFloat) -> CGRect {
    var copy = self
    copy.expand(add)
    return copy
  }
  
  mutating func expand(_ add: CGFloat) {
    origin.x -= add
    origin.y -= add
    size.width += (add * 2)
    size.height += (add * 2)
  }
}

extension Bool {
  var yesNoString: String { self ? "Yes" : "No" }
}
