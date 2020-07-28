//
//  BundleAppInstallHelper.swift
//  androidtools
//
//  Created by didikee on 7/24/20.
//  Copyright © 2020 didikee. All rights reserved.
//

import Foundation

class BundleAppInstallHelper {
    static let AIFX_JKS_PWD = "lunaon123!"
    static let AIFX_ALIAS = "aifx"
    static let AIFX_ALIAS_PWD = "lunaon123!"
    
    static func getInstallShell(_ bundleToolJarPath: String, aabFilePath: String,signFilePath: String, adbPath: String) -> String {
        let shell = """
        bundlejar_location=\(bundleToolJarPath);
        ks_location=\(signFilePath);
        ks_pwd=\(AIFX_JKS_PWD);
        ks_alias=\(AIFX_ALIAS);
        ks_alias_pwd=\(AIFX_ALIAS_PWD);
        app_bundle=\(aabFilePath);
        
        # ouput folder
        aab_folder="/Users/$USER/Downloads/Android/aab/";
        apks_folder="/Users/$USER/Downloads/Android/apks/";
        
        apks_file_name=$(basename "$app_bundle" ".aab")
        apks_location="$apks_folder${apks_file_name}.apks";
        [ -e $apks_location ] && rm $apks_location
        echo "apks输出目录: $apks_location";
        
        echo "正在处理app bundle 转 apks..."
        # app bundle to apks
        java -jar $bundlejar_location build-apks --bundle=$app_bundle --output=$apks_location --ks=$ks_location --ks-pass=pass:$ks_pwd --ks-key-alias=$ks_alias --key-pass=pass:$ks_alias_pwd
        
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
    
    static func getTestCommand() -> String{
        return """
        echo "安装完成"
        """
        //return "java -version";
        //        return "/Users/didikee/Downloads/Android/platform-tools/adb devices";
    }
    
    /// 执行脚本命令
    ///
    /// - Parameters:
    ///   - command: 命令行内容
    ///   - needAuthorize: 执行脚本时,是否需要 sudo 授权
    /// - Returns: 执行结果
    static func runCommand(_ command: String, needAuthorize: Bool) -> (isSuccess: Bool, executeResult: String?) {
        let scriptWithAuthorization = """
        do shell script "\(command)" with administrator privileges
        """
        
        let scriptWithoutAuthorization = """
        do shell script "\(command)"
        """
        
        let script = needAuthorize ? scriptWithAuthorization : scriptWithoutAuthorization
        let appleScript = NSAppleScript(source: script)
        
        var error: NSDictionary? = nil
        let result = appleScript!.executeAndReturnError(&error)
        if let error = error {
            print("执行 \n\(command)\n命令出错:")
            print(error)
            return (false, nil)
        }
        
        return (true, result.stringValue)
    }
    
    // 执行shell脚本片段
    static func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }
    
    // 执行shell脚本片段(测试)
    static func shellTest(_ command: String) {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        
        let outputHandle = pipe.fileHandleForReading
        outputHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                // Update your view with the new text here
                print("New ouput: \(line)")
            } else {
                print("Error decoding data: \(pipe.availableData)")
                
            }
            task.launch()
    
        }
    }
}

