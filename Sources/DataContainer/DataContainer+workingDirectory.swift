//
//  DataContainer+workingDirectory.swift
//  
//
//  Created by ezou on 2021/10/17.
//

import Foundation

private var workingDirectoryLocked: Bool = false
private var workingDirectory: URL = {
    workingDirectoryLocked = true
    #if os(macOS)
    return try! FileManager.default.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil, create: true)
    #else
    return try! FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil, create: true)
    #endif
}()

func CurrentWorkingDirectory() -> URL {
    workingDirectory
}

public enum DataContainerError: Error {
    case workingDirectoryInconsistency
}

extension DataContainer {
    public static func setWorkingDirectory(_ url: URL) throws {
        guard !workingDirectoryLocked else {
            throw DataContainerError.workingDirectoryInconsistency
        }
        workingDirectory = url
    }
}
