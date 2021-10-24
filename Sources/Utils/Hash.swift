//
//  Hash.swift
//  
//
//  Created by ezou on 2021/10/24.
//

import Foundation

enum Hash {
    static func orderedHash(lhs: UInt64, rhs: UInt64) -> UInt64 {
        lhs ^ (rhs + 0x9e3779b9 + (lhs << 6) + (lhs >> 2))
    }
    
    static func unorderedHash(lhs: UInt64, rhs: UInt64) -> UInt64 {
        lhs ^ rhs
    }

    static func hash(string: String) -> UInt64 {
        let charArray = string.utf8CString.dropLast()
        var hash: UInt64 = 0
        for i in stride(from: 0, to: charArray.count, by: 4) {
            var value: Int32 = 0
            for char in charArray[i..<min(i+4, charArray.count)] {
                value = value << 8
                value = value | Int32(char)
            }
            hash = Hash.orderedHash(lhs: hash, rhs: UInt64(value))
        }
        return hash
    }
}
