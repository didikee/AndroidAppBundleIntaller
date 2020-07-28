//
//  CommandRunner.swift
//  androidtools
//
//  Created by didikee on 7/27/20.
//  Copyright © 2020 didikee. All rights reserved.
//

import Foundation

class CommandRunner: NSObject {
    
    /** 同步执行
     *  command:    shell 命令内容
     *  returns:    命令行执行结果，积压在一起返回
     *
     *  使用示例
        let (res, rev) = CommandRunner.sync(command: "ls -l")
        print(rev)
     */
    static func sync(command: String) -> (Int, String) {
        let utf8Command = "export LANG=en_US.UTF-8\n" + command
        return sync(shellPath: "/bin/bash", arguments: ["-c", utf8Command])
    }
    
    /** 同步执行
     *  shellPath:  命令行启动路径
     *  arguments:  命令行参数
     *  returns:    命令行执行结果，积压在一起返回
     *
     *  使用示例
        let (res, rev) = CommandRunner.sync(shellPath: "/usr/sbin/system_profiler", arguments: ["SPHardwareDataType"])
        print(rev)
     */
    static func sync(shellPath: String, arguments: [String]? = nil) -> (Int, String) {
        let task = Process()
        let pipe = Pipe()
        
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        task.environment = environment
        
        if arguments != nil {
            task.arguments = arguments!
        }
        
        task.launchPath = shellPath
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = String(data: data, encoding: String.Encoding.utf8)!
        
        task.waitUntilExit()
        pipe.fileHandleForReading.closeFile()
        
        return (Int(task.terminationStatus), output)
    }
    
    /** 异步执行
     *  command:    shell 命令内容
     *  output:     每行的输出内容实时回调(主线程回调)
     *  terminate:  命令执行结束状态(主线程回调)
     *
     *  使用示例
        CommandRunner.async(command: "ls -l",
                            output: {[weak self] (str) in
                                self?.appendLog(str: str)
                            },
                            terminate: {[weak self] (code) in
                                self?.appendLog(str: "end \(code)")
                            })
     */
    static func async(command: String,
                      output: ((String) -> Void)? = nil,
                      terminate: ((Int) -> Void)? = nil) {
        let utf8Command = "export LANG=en_US.UTF-8\n" + command
        async(shellPath: "/bin/bash", arguments: ["-c", utf8Command], output:output, terminate:terminate)
    }
    
    /** 异步执行
     *  shellPath:  命令行启动路径
     *  arguments:  命令行参数
     *  output:     每行的输出内容实时回调(主线程回调)
     *  terminate:  命令执行结束状态(主线程回调)
     *
     *  使用示例
        CommandRunner.async(shellPath: "/usr/sbin/system_profiler",
                            arguments: ["SPHardwareDataType"],
                            output: {[weak self] (str) in
                                self?.appendLog(str: str)
                            },
                            terminate: {[weak self] (code) in
                                self?.appendLog(str: "end \(code)")
                            })
     */
    static func async(shellPath: String,
                      arguments: [String]? = nil,
                      output: ((String) -> Void)? = nil,
                      terminate: ((Int) -> Void)? = nil) {
        DispatchQueue.global().async {
            let task = Process()
            let pipe = Pipe()
            let outHandle = pipe.fileHandleForReading
            
            var environment = ProcessInfo.processInfo.environment
            environment["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
            task.environment = environment
            
            if arguments != nil {
                task.arguments = arguments!
            }
            
            task.launchPath = shellPath
            task.standardOutput = pipe
            
            outHandle.waitForDataInBackgroundAndNotify()
            var obs1 : NSObjectProtocol!
            obs1 = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable,
                                                          object: outHandle, queue: nil) {  notification -> Void in
                                                            let data = outHandle.availableData
                                                            if data.count > 0 {
                                                                if let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                                                                    DispatchQueue.main.async {
                                                                        output?(str as String)
                                                                    }
                                                                }
                                                                outHandle.waitForDataInBackgroundAndNotify()
                                                            } else {
                                                                NotificationCenter.default.removeObserver(obs1)
                                                                pipe.fileHandleForReading.closeFile()
                                                            }
            }
            
            var obs2 : NSObjectProtocol!
            obs2 = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification,
                                                          object: task, queue: nil) { notification -> Void in
                                                            DispatchQueue.main.async {
                                                                terminate?(Int(task.terminationStatus))
                                                            }
                                                            NotificationCenter.default.removeObserver(obs2)
            }
            
            task.launch()
            task.waitUntilExit()
        }
    }
}
