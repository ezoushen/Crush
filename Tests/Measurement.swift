//
//  Measurement.swift
//  
//
//  Created by ezou on 2021/10/14.
//

import Foundation

struct Measurement {
    let name: String
    let duration: Double
    let memoryConsumptionInBytes: UInt64
}

internal func measurement(name: String? = nil, block: () -> Void) -> Measurement {
    let startMemory = memory_usage()
    let startTime = mach_absolute_time()
    block()
    let endTime = mach_absolute_time()
    let endMemory = memory_usage()
    return Measurement(
        name: name ?? "untitled", 
        duration: mach_to_milliseconds(endTime - startTime),
        memoryConsumptionInBytes: endMemory - startMemory)
}

private var timebase_info: mach_timebase_info = {
    var info = mach_timebase_info_data_t()
    mach_timebase_info(&info)
    return info
}()

private func mach_to_milliseconds(_ time: UInt64) -> Double {
    return Double(time * UInt64(timebase_info.numer)) / Double(timebase_info.denom) / 1_000_000
}

private func memory_usage() -> UInt64 {
    var taskInfo = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }

    if kerr == KERN_SUCCESS {
        return taskInfo.resident_size
    }
    else {
        fatalError("Error with task_info(): " +
                   (String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error"))
    }
}
