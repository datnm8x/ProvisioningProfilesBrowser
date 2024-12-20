//
//  Entitlement.swift
//  SwiftyProvisioningProfile
//
//  Created by Sherlock, James on 13/05/2018.
//

import Foundation

/// Enum describing a property lists value inside of a dictionary
public enum PropertyListDictionaryValue: Codable, Equatable {
    
    case string(String)
    case bool(Bool)
    case array([PropertyListDictionaryValue])
    case unknown
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let array = try? container.decode([PropertyListDictionaryValue].self) {
            self = .array(array)
        } else {
            self = .unknown
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let string):
            try container.encode(string)
        case .bool(let bool):
            try container.encode(bool)
        case .array(let array):
            try container.encode(array)
        case .unknown:
            break
        }
        
    }
    
    var value: Any? {
        switch self {
        case .string(let string): return string
        case .array(let array): return array.map({ $0.value })
        case .bool(let bool): return bool
        case .unknown: return nil
        }
    }
    
    var string: String? {
        switch self {
        case .string(let string): return string
        case .array(let array): return array.compactMap({ $0.value as? String }).joined(separator: ", ")
        case .bool(let bool): return bool ? "true" : "false"
        case .unknown: return nil
        }
    }
}
