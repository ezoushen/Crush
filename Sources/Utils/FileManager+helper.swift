//
//  FileManager+helper.swift
//  
//
//  Created by ezou on 2021/10/24.
//

import Foundation

extension FileManager {
    func removeItemIfExists(atPath path: String) throws {
        if fileExists(atPath: path) {
            try removeItem(atPath: path)
        }
    }
}
