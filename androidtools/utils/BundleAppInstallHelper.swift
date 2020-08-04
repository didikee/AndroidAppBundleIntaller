//
//  BundleAppInstallHelper.swift
//  androidtools
//
//  Created by didikee on 7/24/20.
//  Copyright © 2020 didikee. All rights reserved.
//

import Foundation

class BundleAppInstallHelper {
    static let OUTPUT_LOG = "/Users/$USER/Downloads/Android/output.log"
    static let AAB_FOLDER = "/Users/$USER/Downloads/Android/aab/"
    static let APKS_FOLDER = "/Users/$USER/Downloads/Android/apks/"
    
    static func getInstallShell(_ bundleToolJarPath: String, aabFilePath: String,signFilePath: String, adbPath: String,
                                signPwd: String, alias: String, aliasPwd: String
    ) -> String {
        let shell = """
        bundlejar_location=\(bundleToolJarPath);
        ks_location=\(signFilePath);
        ks_pwd=\(signPwd);
        ks_alias=\(alias);
        ks_alias_pwd=\(aliasPwd);
        app_bundle=\(aabFilePath);
        
        # ouput folder
        aab_folder="/Users/$USER/Downloads/Android/aab/";
        apks_folder="/Users/$USER/Downloads/Android/apks/";
        
        apks_file_name=$(basename "$app_bundle" ".aab")
        apks_location="${apks_folder}${apks_file_name}.apks";
        [ -e $apks_location ] && rm $apks_location
        echo "apks输出目录: $apks_location";
        
        echo "正在处理app bundle 转 apks..."
        # app bundle to apks
        java -jar $bundlejar_location build-apks --bundle=$app_bundle --output=$apks_location --ks=$ks_location --ks-pass=pass:$ks_pwd --ks-key-alias=$ks_alias --key-pass=pass:$ks_alias_pwd &> \(OUTPUT_LOG)
        
        if [ ! -e $apks_location ]; then
        exit
        fi
        
        echo "正在安装apks..."
        # install apks to android device
        java -jar $bundlejar_location install-apks --apks=$apks_location --adb=\(adbPath)
        
        echo "安装完成"
        echo "执行结束";
        """
        
        return shell;
    }
    
    static func getIntallApksShell(_ bundleToolJarPath: String, adbPath: String, apksFilename: String
    ) -> String {
        let shell = """
        bundlejar_location=\(bundleToolJarPath);
        
        # ouput folder
        aab_folder="\(AAB_FOLDER)";
        apks_folder="\(APKS_FOLDER)";
        
        apks_location="${apks_folder}\(apksFilename)";
        echo "apks输出目录: $apks_location";
        
        echo "正在安装apks..."
        # install apks to android device
        java -jar $bundlejar_location install-apks --apks=$apks_location --adb=\(adbPath) &> \(OUTPUT_LOG)
        
        echo "完整完成:$apks_location"
        """
        return shell;
    }
    
    static func getBundle2ApksShell(_ bundleToolJarPath: String, aabFilePath: String,signFilePath: String, adbPath: String,
                                    signPwd: String, alias: String, aliasPwd: String, apksFilename: String
    ) -> String {
        let shell = """
        bundlejar_location=\(bundleToolJarPath);
        ks_location=\(signFilePath);
        ks_pwd=\(signPwd);
        ks_alias=\(alias);
        ks_alias_pwd=\(aliasPwd);
        app_bundle=\(aabFilePath);
        
        # ouput folder
        aab_folder="\(AAB_FOLDER)";
        apks_folder="\(APKS_FOLDER)";
        
        apks_location="${apks_folder}\(apksFilename)";
        # [ -e $apks_location ] && rm $apks_location
        # rm -f $apks_location
        echo "apks输出目录: $apks_location";
        
        echo "正在处理app bundle 转 apks..."
        # app bundle to apks
        java -jar $bundlejar_location build-apks --bundle=$app_bundle --output=$apks_location --ks=$ks_location --ks-pass=pass:$ks_pwd --ks-key-alias=$ks_alias --key-pass=pass:$ks_alias_pwd --mode=universal --overwrite &> \(OUTPUT_LOG)
        """
        return shell;
    }
    
    static func getTestCommand() -> String{
        return """
        echo "安装完成"
        """
        //return "java -version";
        //        return "/Users/didikee/Downloads/Android/platform-tools/adb devices";
    }
    
    // 执行shell脚本片段
    static func shell(_ command: String) {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.launch()
        task.waitUntilExit()
    }
    
    // 执行shell脚本片段(测试)
    static func shellTest(_ command: String) {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.launch()
    }
    
    // 获取java version 命令
    static func getJavaVersionCmd(_ outputFile: URL) -> String{
        return """
        log_file=\(outputFile.path)
        java -version &> ${log_file}
        """
    }
    
    // 获取adb devices 命令
    static func getAdbDevicesCmd(_ outputFile: URL) -> String{
        let currentAppContentPath = ResourceHelper.getCurrentAppContentPath()
        let adb = currentAppContentPath + "/Resources/platform-tools/adb"
        return """
        log_file=\(outputFile.path)
        \(adb) devices &> ${log_file}
        """
    }
    
    // 删除文件
    static func deleteFile(_ file: URL) -> Bool{
        do {
            try FileManager.default.removeItem(at: file)
        } catch  {
            
        }
        return FileManager.default.fileExists(atPath: file.path)
    }
    
    static func clearFileContent(_ file: URL){
        if FileManager.default.fileExists(atPath: file.path) {
            do {
                let text = ""
                try text.write(to: file, atomically: false, encoding: .utf8)
            } catch {
                print(error)
            }
        }
    }
    
    // 通过日志获取设备数
    static func getDeviceCountFromLog(_ log: String) -> Int{
        let regex = "device"
        if log.isEmpty {
            return 0
        }
        do {
            let regular = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let matchResult = regular.matches(in: log, options: .reportProgress, range: NSRange(location: 0, length: log.count))
            if matchResult.count > 1 {
                // 仅当有设备时才返回设备数
                return matchResult.count - 1
            }
        } catch {
            print(error)
        }
        return 0
    }
    
    // 通过日志检测java环境
    static func getJavaVersionFromLog(_ log: String) -> String{
        let regex = "\".*\""
        if log.isEmpty {
            return ""
        }
        do {
            let regular = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let matchResult = regular.firstMatch(in: log, options: .reportProgress, range: NSRange(location: 0, length: log.count))
            let range = matchResult?.range
            if range != nil {
                let version = (log as NSString).substring(with: NSRange(location: range!.location + 1, length: range!.length - 2))
                return version
            }
        } catch {
            print(error)
        }
        return ""
    }
    
    // 获取log文件
   static func getLogFile() -> URL {
       var logFile = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        logFile.appendPathComponent("Android")
        logFile.appendPathComponent("output.log", isDirectory: false)
        if !FileManager.default.fileExists(atPath: logFile.path) {
            FileManager.default.createFile(atPath: logFile.path, contents: nil, attributes: nil)
        }
        return logFile
    }
    
    // 获取apks的文件
    static func getApksFile(_ apksFilename:String) -> URL {
       var apksFile = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        apksFile.appendPathComponent("Android")
        apksFile.appendPathComponent("apks")
        apksFile.appendPathComponent(apksFilename, isDirectory: false)
        return apksFile
    }
}

