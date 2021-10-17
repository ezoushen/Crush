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
    return try! FileManager.default.url(
        for: .documentDirectory,
        in: .allDomainsMask,
        appropriateFor: nil, create: true)
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
