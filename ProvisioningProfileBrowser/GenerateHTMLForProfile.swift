//
//  GenerateHTMLForProfile.swift
//  ProvisioningProfileBrowser
//
//  Created by Nguyen Mau Dat on 17/05/2022.
//

import Foundation

enum ExpirationStatus {
  case expired
  case expiring
  case valid

  static func withDate(_ date: Date) -> ExpirationStatus {
    let now = Date()
    let dateComponents = Calendar.current.dateComponents([.day], from: now, to: date)
    if date.compare(now) == .orderedAscending { return .expired }
    else if dateComponents.day ?? 0 < 30 { return .expiring }
    else { return .valid }
  }
}

