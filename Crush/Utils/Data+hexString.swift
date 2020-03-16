//
//  Data.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/1/10.
//  Copyright © 2020 ezou. All rights reserved.
//

import Foundation

extension Data {
    var hexString: String {
        reduce("") {$0 + String(format: "%02x", $1)}
    }
}
