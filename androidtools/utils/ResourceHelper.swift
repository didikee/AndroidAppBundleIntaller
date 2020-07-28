//
//  ResourceHelper.swift
//  androidtools
//
//  Created by didikee on 7/24/20.
//  Copyright © 2020 didikee. All rights reserved.
//
import Darwin
import Foundation


class ResourceHelper {
    static func getMainPath() -> String{
        
        // Call proc_listallpids once with nil/0 args to get the current number of pids
        let initialNumPids = proc_listallpids(nil, 0)

        // Allocate a buffer of these number of pids.
        // Make sure to deallocate it as this class does not manage memory for us.
        let buffer = UnsafeMutablePointer<pid_t>.allocate(capacity: Int(initialNumPids))
        defer {
            buffer.deallocate()
        }

        // Calculate the buffer's total length in bytes
        let bufferLength = initialNumPids * Int32(MemoryLayout<pid_t>.size)

        // Call the function again with our inputs now ready
        let numPids = proc_listallpids(buffer, bufferLength)

        // Loop through each pid
        for i in 0..<numPids {

            // Print the current pid
            let pid = buffer[Int(i)]
            print("[\(i)] \(pid)")

            // Allocate a buffer to store the name
            let nameBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(MAXPATHLEN))
            defer {
                nameBuffer.deallocate()
            }

            // Now get and print the name. Not all processes return a name here...
            let nameLength = proc_name(pid, nameBuffer, UInt32(MAXPATHLEN))
            if nameLength > 0 {
                let name = String(cString: nameBuffer)
                print("  name=\(name)")
            }

            // ...so also get the process' path
            let pathBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(MAXPATHLEN))
            defer {
                pathBuffer.deallocate()
            }
            let pathLength = proc_pidpath(pid, pathBuffer, UInt32(MAXPATHLEN))
            if pathLength > 0 {
                let path = String(cString: pathBuffer)
                print("  path=\(path)")
            }
        }
        return ""
    }
    
    
    static func getCurrentPidPath() -> String{
        // Print the current pid
        let pid = getpid()
    
        // Allocate a buffer to store the name
        let nameBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(MAXPATHLEN))
        defer {
            nameBuffer.deallocate()
        }

        // Now get and print the name. Not all processes return a name here...
        let nameLength = proc_name(pid, nameBuffer, UInt32(MAXPATHLEN))
        if nameLength > 0 {
            let name = String(cString: nameBuffer)
            print("  name=\(name)")
        }

        // ...so also get the process' path
        let pathBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(MAXPATHLEN))
        defer {
            pathBuffer.deallocate()
        }
        let pathLength = proc_pidpath(pid, pathBuffer, UInt32(MAXPATHLEN))
        if pathLength > 0 {
            return String(cString: pathBuffer)
        }
        return ""
    }
    

    static func getCurrentAppContentPath() -> String{
        let currentPidPath = getCurrentPidPath()
        print(currentPidPath)
        var url = URL.init(fileURLWithPath: currentPidPath)
        url.deleteLastPathComponent()
        url.deleteLastPathComponent()
        return url.path
    }
}
