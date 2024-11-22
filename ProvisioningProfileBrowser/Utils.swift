//
//  Utils.swift
//  ProvisioningProfileBrowser
//
//  Created by Nguyen Mau Dat on 22/11/24.
//

import Foundation
import KeyboardShortcuts

struct Terminal {
    static func exeShell(_ command: String) -> String {

        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return output
    }
}

extension KeyboardShortcuts.Name {
    static let copy = Self("Copy")
    static let delete = Self("Move to Trash")
    static let revealFinder = Self("Reveal in Finder")
}
