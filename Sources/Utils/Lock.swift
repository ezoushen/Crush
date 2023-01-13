//
//  UnfairLock.swift
//  
//
//  Created by EZOU on 2023/1/13.
//

import Foundation

class UnfairLock {
    private var _lock = os_unfair_lock()

    func lock() {
        os_unfair_lock_lock(&_lock)
    }

    func unlock() {
        os_unfair_lock_unlock(&_lock)
    }

    func tryLock() -> Bool {
        os_unfair_lock_trylock(&_lock)
    }

    func assertOwner() {
        os_unfair_lock_assert_owner(&_lock)
    }

    func assertNotOwner() {
        os_unfair_lock_assert_not_owner(&_lock)
    }
}
