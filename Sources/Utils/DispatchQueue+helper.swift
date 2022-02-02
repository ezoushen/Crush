//
//  DispatchQueue+helper.swift
//  
//
//  Created by ezou on 2021/10/17.
//

import Foundation

extension DispatchQueue {
    @inlinable
    static func performMainThreadTask(_ block: @escaping () -> Void){
        if Thread.isMainThread {
            return block()
        }
        DispatchQueue.main.async {
            block()
        }
    }
}
