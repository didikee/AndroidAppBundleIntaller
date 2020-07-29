//
//  ViewController.swift
//  androidtools
//
//  Created by didikee on 7/21/20.
//  Copyright © 2020 didikee. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var bundleToolPath: NSTextField!
    @IBOutlet weak var inputAndroidAabFilePath: NSTextField!
    @IBOutlet weak var inputSignFilePath: NSTextFieldCell!
    
    @IBOutlet weak var textSignPwd: NSTextFieldCell!
    @IBOutlet weak var textAlias: NSTextField!
    @IBOutlet weak var textAliasPwd: NSTextField!
    
    @IBOutlet weak var btInstall: NSButton!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // reset window height to 400
        // self.view.window?.setFrame(NSRect(x:0,y:0,width: 480,height: 400), display: true)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        self.view.window?.title = "Android AppBundle 安装工具\(appVersion ?? "")"
        self.progressBar.isHidden = true
        
        //UserDefaults.standard.removeObject(forKey: ConfigsHelper.KEY_APP_INSTALL_DICT)
        setLastConfigs()
        
    }
    
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
        
    }
    // MARK: - ui action
    
    @IBAction func submitBtnClick(_ sender: Any) {
        // installApp
        btInstall.isEnabled = false
        self.progressBar.isHidden = false
        self.progressBar.startAnimation(sender)
        let startTime = CFAbsoluteTimeGetCurrent()

        DispatchQueue.global().async {
            // working
            //sleep(5)
            self.installApp()
            
            DispatchQueue.main.async {
                self.btInstall.isEnabled = true
                self.progressBar.isHidden = true
                self.progressBar.stopAnimation(sender)

                self.showInstallFinishDialog(startTime)
            }
        }
    }
    
    @IBAction func selectBundleJarFile(_ sender: Any) {
        // 选择BundleTool.jar文件
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.title = "选择BundleTool文件"
        openPanel.allowedFileTypes = ["jar"]
        
        openPanel.beginSheetModal(for:self.view.window!) { (response) in
            if response == .OK {
                let selectedPath = openPanel.url!.path
                // do whatever you what with the file path
                self.bundleToolPath.stringValue = selectedPath
                print(selectedPath)
            }
            openPanel.close()
        }
    }
    
    @IBAction func selectAndoidSignFile(_ sender: Any) {
        // 选择签名文件.jks
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.title = "选择签名文件"
        openPanel.allowedFileTypes = ["jks"]
        
        openPanel.beginSheetModal(for:self.view.window!) { (response) in
            if response == .OK {
                let selectedPath = openPanel.url!.path
                // do whatever you what with the file path
                self.inputSignFilePath.stringValue = selectedPath
                print(selectedPath)
            }
            openPanel.close()
        }
    }
    
    @IBAction func selectAndroidAabFile(_ sender: Any) {
        // 选择.aab 的文件
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.title = "选择安装文件"
        openPanel.allowedFileTypes = ["aab"]
        
        openPanel.beginSheetModal(for:self.view.window!) { (response) in
            if response == .OK {
                let selectedPath = openPanel.url!.path
                // do whatever you what with the file path
                self.inputAndroidAabFilePath.stringValue = selectedPath
                print(selectedPath)
            }
            openPanel.close()
        }
    }
    
    // 提示错误
    func showErrorDialog(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = message
            alert.informativeText = ""
            alert.alertStyle = .warning
            alert.addButton(withTitle: "好的")
            alert.runModal()
        }
    }
    
    // 安装完成
    func showInstallFinishDialog(_ start: CFAbsoluteTime) {
        let spent = CFAbsoluteTimeGetCurrent() - start
        let alert = NSAlert()
        alert.messageText = "安装结束"
        alert.informativeText = """
        本次安装耗时：\(Int(spent)) 秒, 请查看手机确认是否安装成功。
        
        如果安装失败请查看注意事项获取更多帮助。
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }
    
    
    // 设置上次配置
    func setLastConfigs() {
        // init last configs
        let configsDict = ConfigsHelper.getConfigs()
        if !configsDict.isEmpty {
            print("字典不为空")
            self.inputSignFilePath.stringValue = configsDict[ConfigsHelper.KEY_SIGN_PATH]!
            self.textSignPwd.stringValue = configsDict[ConfigsHelper.KEY_SING_PWD]!
            self.textAlias.stringValue = configsDict[ConfigsHelper.KEY_ALIAS]!
            self.textAliasPwd.stringValue = configsDict[ConfigsHelper.KEY_ALIAS_PWD]!
        }
    }
    
    // 安装app
    func installApp() {
        let aabFilePath = self.inputAndroidAabFilePath.stringValue;
        let signFilePath = self.inputSignFilePath.stringValue;
        let bundleToolJarPath = self.bundleToolPath.stringValue;
        
        let signPwd = self.textSignPwd.stringValue;
        let alias = self.textAlias.stringValue
        let aliasPwd = self.textAliasPwd.stringValue
        
        if signFilePath.isEmpty {
            showErrorDialog("请选择签名文件(.jks)")
            return
        }
        
        if signPwd.isEmpty {
            showErrorDialog("请输入签名密码")
            return
        }
        if alias.isEmpty {
            showErrorDialog("请输入别名")
            return
        }
        if aliasPwd.isEmpty {
            showErrorDialog("请输入别名密码")
            return
        }
        
        if aabFilePath.isEmpty {
            showErrorDialog("请选择安卓安装文件(.aab)")
            return
        }
        // save configs
        ConfigsHelper.setConfigs(signFilePath, signPwd: signPwd, alias: alias, aliasPwd: aliasPwd)
        
        
        // bundletool.jar 和 adb 地址
        let currentAppContentPath = ResourceHelper.getCurrentAppContentPath()
        let bundlejar = currentAppContentPath + "/Resources/bundletool.jar"
        let adb = currentAppContentPath + "/Resources/platform-tools/adb"
 
        let shell = BundleAppInstallHelper.getInstallShell(bundlejar,aabFilePath: aabFilePath, signFilePath: signFilePath,adbPath: adb);

        BundleAppInstallHelper.shell(shell);
    }
    
    func shellTest() {
        //        let command = """
        //        java -version
        //        """
        //            let task = Process()
        //            let pipe = Pipe()
        //
        //            task.standardOutput = pipe
        //            task.arguments = ["-c", command]
        //            task.launchPath = "/bin/bash"
                    
        //            let outputHandle = pipe.fileHandleForReading
        //            outputHandle.readabilityHandler = { pipe in
        //                if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
        //                    // Update your view with the new text here
        //                    print("New ouput: \(line)")
        //                } else {
        //                    print("Error decoding data: \(pipe.availableData)")
        //
        //                }
        //            }
                
        //        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
        //            let data = fileHandle.availableData
        //            print("received data: \(data.count)")
        //            print(String(data: data, encoding: .utf8) ?? "")
        //            // Display the new output appropriately in a NSTextView for example
        //
        //        }
        //         task.launch()
        //        task.waitUntilExit()
        //        print("代码结束")
                
                let task = Process()

                task.launchPath = "/bin/bash"
                //task.arguments = ["-c", "echo 1 ; sleep 1 ; echo 2 ; sleep 1 ; echo 3 ; sleep 1 ; echo 4"]
                // task.arguments = ["-c", "java -version"]
        task.arguments = ["-c", "adb devices"]

                let pipe = Pipe()
                task.standardOutput = pipe
                //let outHandle = pipe.fileHandleForReading
                task.launch()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data,encoding: String.Encoding.utf8)!
        //        var output = String()

        //        outHandle.readabilityHandler = { pipe in
        //            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
        //                // Update your view with the new text here
        //                if line.count > 0 {
        //                    bigOutput.append(line)
        //                }
        //                // print("New ouput: \(line)")
        //            } else {
        //                print("Error decoding data: \(pipe.availableData)")
        //            }
        //        }

                
                //task.waitUntilExit()
                print("end")
                print("结束:\(output)")
    }
}

