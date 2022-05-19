//
//  Date+Ex.swift
//  EXViOSBaseExt
//
//  Created by Dat Ng on 14/05/2020.
//  Copyright © 2020 datnm. All rights reserved.
//

import Foundation

public extension Date {
  // "yyyy-MM-dd'T'HH:mm:ssZZZZZ", Locale(identifier: "en_US_POSIX")
  func toStringFormat8601() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    dateFormatter.locale = Locale.usPOSIX
    return dateFormatter.string(from: self)
  }

  func toStringFormatRFC3339() -> String? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    dateFormatter.locale = Locale.usPOSIX
    return dateFormatter.string(from: self)
  }

  func toString(format dateFormat: String, locale: Locale = .usPOSIX, timeZone: TimeZone? = nil) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat
    dateFormatter.locale = locale
    if timeZone != nil { dateFormatter.timeZone = timeZone }
    return dateFormatter.string(from: self)
  }

  func toStringJpTimeZone(format dateFormat: String) -> String {
    toString(format: dateFormat, timeZone: TimeZone.jp)
  }

  var isFirstDayOfMonth: Bool {
    Calendar.current.dateComponents(Set<Calendar.Component>([.day]), from: self).day == 1
  }

  var isLastDayOfMonth: Bool {
    addingTimeInterval(24 * 60 * 60).isFirstDayOfMonth
  }

  var isFirstMonthOfYear: Bool {
    Calendar.current.dateComponents(Set<Calendar.Component>([.month]), from: self).month == 1
  }

  var day: Int {
    get {
      Calendar.current.dateComponents(Set<Calendar.Component>([.day]), from: self).day ?? 0
    }
    set {
      var dateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: self)
      dateComponents.day = newValue
      guard let newDate = Calendar.current.date(from: dateComponents) else {
        return
      }
      self = newDate
    }
  }

  var month: Int {
    get {
      Calendar.current.dateComponents(Set<Calendar.Component>([.month]), from: self).month ?? 0
    }
    set {
      var dateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: self)
      dateComponents.month = newValue
      guard let newDate = Calendar.current.date(from: dateComponents) else {
        return
      }
      self = newDate
    }
  }

  var year: Int {
    get {
      Calendar.current.dateComponents(Set<Calendar.Component>([.year]), from: self).year ?? 0
    }
    set {
      let offsetValue = newValue - self.year
      guard let newDate = Calendar.current.date(byAdding: Calendar.Component.year, value: offsetValue, to: self) else {
        return
      }
      self = newDate
    }
  }

  var second: Int {
    get {
      Calendar.current.dateComponents(Set<Calendar.Component>([.second]), from: self).second ?? 0
    }
    set {
      var dateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: self)
      dateComponents.second = newValue
      guard let newDate = Calendar.current.date(from: dateComponents) else {
        return
      }
      self = newDate
    }
  }

  var minute: Int {
    get {
      Calendar.current.dateComponents(Set<Calendar.Component>([.minute]), from: self).minute ?? 0
    }
    set {
      var dateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: self)
      dateComponents.minute = newValue
      guard let newDate = Calendar.current.date(from: dateComponents) else {
        return
      }
      self = newDate
    }
  }

  var hour: Int {
    get {
      Calendar.current.dateComponents(Set<Calendar.Component>([.hour]), from: self).hour ?? 0
    }
    set {
      var dateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: self)
      dateComponents.hour = newValue
      guard let newDate = Calendar.current.date(from: dateComponents) else {
        return
      }
      self = newDate
    }
  }

  func isEqualDateIgnoreTime(toDate: Date?) -> Bool {
    if let dateCompare = toDate {
      return day == dateCompare.day && month == dateCompare.month && year == dateCompare.year
    }
    return false
  }

  var isToday: Bool { isEqualDateIgnoreTime(toDate: Date()) }
  var isTomorrow: Bool { isEqualDateIgnoreTime(toDate: Date().addingDays(1)) }
  var isWeekend: Bool { Calendar.current.isDateInWeekend(self) }
  var isThisWeek: Bool { Calendar.current.isDateInThisWeek(self) }
  var isNextWeek: Bool { Calendar.current.isDateInNextWeek(self) }
  var isThisMonth: Bool { Calendar.current.isDateInThisMonth(self) }
  var isNextMonth: Bool { Calendar.current.isDateInNextMonth(self) }

  // interval must be evenly divided into 60. default is 0. min is 0, max is 30
  init(minuteInterval: Int, since date: Date = Date()) {
    self = date
    guard minuteInterval > 1 else { return }
    let minuteInterval = Int(date.minute / minuteInterval) * minuteInterval
    self.minute = minuteInterval
  }

  func addingMinutes(_ mins: Int) -> Date {
    addingTimeInterval(TimeInterval(mins * 60))
  }

  func addingHours(_ hours: Int) -> Date {
    addingTimeInterval(TimeInterval(hours * 60 * 60))
  }

  func addingDays(_ days: Int) -> Date {
    addingTimeInterval(TimeInterval(days * 24 * 60 * 60))
  }

  mutating func addMinutes(_ mins: Int) {
    self = addingTimeInterval(TimeInterval(mins * 60))
  }

  mutating func addHours(_ hours: Int) {
    self = addingTimeInterval(TimeInterval(hours * 60 * 60))
  }

  mutating func addDays(_ days: Int) {
    self = addingTimeInterval(TimeInterval(days * 24 * 60 * 60))
  }

  func daysIgnoreTimeSince(_ date: Date) -> Int {
    var calComponents = Calendar.current.dateComponents(in: TimeZone.current, from: date)
    calComponents.day = day
    calComponents.month = month
    calComponents.year = year
    let calDate = Calendar.current.date(from: calComponents) ?? self
    return Calendar.current.dateComponents([Calendar.Component.day], from: date, to: calDate).day ?? 0
  }

  func set(year: Int? = nil, month: Int? = nil, day: Int? = nil,
           hour: Int? = nil, minute: Int? = nil, second: Int? = nil) -> Date
  {
    var dateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: self)
    if let y = year { dateComponents.year = y }
    if let mon = month { dateComponents.month = mon }
    if let day = day { dateComponents.day = day }
    if let h = hour { dateComponents.hour = h }
    if let min = minute { dateComponents.minute = min }
    if let sec = second { dateComponents.second = sec }
    guard let newDate = Calendar.current.date(from: dateComponents) else {
      return self
    }

    return newDate
  }

  mutating func mutableSet(year: Int? = nil, month: Int? = nil, day: Int? = nil,
                           hour: Int? = nil, minute: Int? = nil, second: Int? = nil)
  {
    self = set(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
  }
}

public extension TimeZone {
  init?(hoursFromGMT: Int) {
    self.init(secondsFromGMT: hoursFromGMT * 3600)
  }

  static var jp = TimeZone(hoursFromGMT: 9) ?? TimeZone.current
}

public extension Int {
  var toDateByTimestamp: Date {
    Date(timeIntervalSince1970: TimeInterval(self))
  }
}

public extension Int64 {
  var toDateByTimestamp: Date {
    Date(timeIntervalSince1970: TimeInterval(self))
  }
}

public extension Double {
	var toDateByTimestamp: Date {
		Date(timeIntervalSince1970: TimeInterval(self))
	}
}

public extension Calendar {
  private var currentDate: Date { Date() }

  func isDateInThisWeek(_ date: Date) -> Bool {
    isDate(date, equalTo: currentDate, toGranularity: .weekOfYear)
  }

  func isDateInThisMonth(_ date: Date) -> Bool {
    isDate(date, equalTo: currentDate, toGranularity: .month)
  }

  func isDateInNextWeek(_ date: Date) -> Bool {
    guard let nextWeek = self.date(byAdding: DateComponents(weekOfYear: 1), to: currentDate) else {
      return false
    }
    return isDate(date, equalTo: nextWeek, toGranularity: .weekOfYear)
  }

  func isDateInNextMonth(_ date: Date) -> Bool {
    guard let nextMonth = self.date(byAdding: DateComponents(month: 1), to: currentDate) else {
      return false
    }
    return isDate(date, equalTo: nextMonth, toGranularity: .month)
  }

  func isDateInFollowingMonth(_ date: Date) -> Bool {
    guard let followingMonth = self.date(byAdding: DateComponents(month: 2), to: currentDate) else {
      return false
    }
    return isDate(date, equalTo: followingMonth, toGranularity: .month)
  }
}

public extension Locale {
  static let usPOSIX = Locale(identifier: "en_US_POSIX")
}

/*
 let dateFormatter = DateFormatter()
 dateFormatter.dateFormat = "HH:mm:ss"
 var dateFromStr = dateFormatter.date(from: "12:16:45")!
 
 dateFormatter.dateFormat = "hh:mm:ss a 'on' MMMM dd, yyyy"
 //Output: 12:16:45 PM on January 01, 2000
 
 dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
 //Output: Sat, 1 Jan 2000 12:16:45 +0600
 
 dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
 //Output: 2000-01-01T12:16:45+0600
 
 dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
 //Output: Saturday, Jan 1, 2000
 
 dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
 //Output: 01-01-2000 12:16
 
 dateFormatter.dateFormat = "MMM d, h:mm a"
 //Output: Jan 1, 12:16 PM
 
 dateFormatter.dateFormat = "HH:mm:ss.SSS"
 //Output: 12:16:45.000
 
 dateFormatter.dateFormat = "MMM d, yyyy"
 //Output: Jan 1, 2000
 
 dateFormatter.dateFormat = "MM/dd/yyyy"
 //Output: 01/01/2000
 
 dateFormatter.dateFormat = "hh:mm:ss a"
 //Output: 12:16:45 PM
 
 dateFormatter.dateFormat = "MMMM yyyy"
 //Output: January 2000
 
 dateFormatter.dateFormat = "dd.MM.yy"
 //Output: 01.01.00
 
 //Output: Customisable AP/PM symbols
 dateFormatter.amSymbol = "am"
 dateFormatter.pmSymbol = "Pm"
 dateFormatter.dateFormat = "a"
 //Output: Pm
 
 // Usage
 var timeFromDate = dateFormatter.string(from: dateFromStr)
 print(timeFromDate)
 */
