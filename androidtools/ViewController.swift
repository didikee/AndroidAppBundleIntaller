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
    @IBOutlet weak var textProcessMessage: NSTextField!
    
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
        // check params in main thread
        let aabFilePath = self.inputAndroidAabFilePath.stringValue;
        let signFilePath = self.inputSignFilePath.stringValue;
         
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
        // installApp
        btInstall.isEnabled = false
        self.progressBar.isHidden = false
        self.progressBar.startAnimation(sender)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // init android folder
        let isAndroidFolderExist = FileHelper.checkInitAndroidFodler()
        if !isAndroidFolderExist {
            print("Something went wrong,'Android' folder create failed.")
        }

        DispatchQueue.global().async {
            // working
            // check java version
            BundleAppInstallHelper.clearFileContent(self.getLogFile())
            print(self.getLogFile().path)
            BundleAppInstallHelper.shell(BundleAppInstallHelper.getJavaVersionCmd(self.getLogFile()))
            let javaVersion = BundleAppInstallHelper.getJavaVersionFromLog(self.getFileContent(self.getLogFile()))
            if javaVersion.isEmpty{
                DispatchQueue.main.async {
                    self.btInstall.isEnabled = true
                    self.progressBar.isHidden = true
                    self.progressBar.stopAnimation(sender)

                    self.showErrorDialog("检测到JDK未安装，请在浏览器中搜索JDK并安装。")
                }
                return
            }
            // check connect devices
            BundleAppInstallHelper.clearFileContent(self.getLogFile())
            BundleAppInstallHelper.shell(BundleAppInstallHelper.getAdbDevicesCmd(self.getLogFile()))
            let deviceCount = BundleAppInstallHelper.getDeviceCountFromLog(self.getFileContent(self.getLogFile()))
            if deviceCount > 1{
                DispatchQueue.main.async {
                    self.btInstall.isEnabled = true
                    self.progressBar.isHidden = true
                    self.progressBar.stopAnimation(sender)

                    self.showErrorDialog("检测到多台连接设备，请移除多余设备并确保只有一台设备连接。")
                }
                return
            }
            if deviceCount < 1 {
                DispatchQueue.main.async {
                    self.btInstall.isEnabled = true
                    self.progressBar.isHidden = true
                    self.progressBar.stopAnimation(sender)

                    self.showErrorDialog("请连接安卓手机。如果你已经连接了安卓手机，请开启开发者选中的USB调试模式。")
                }
                return
            }
            // 执行安装程序
            BundleAppInstallHelper.clearFileContent(self.getLogFile())
            
            // bundletool.jar 和 adb 地址
            let currentAppContentPath = ResourceHelper.getCurrentAppContentPath()
            let bundlejar = currentAppContentPath + "/Resources/bundletool.jar"
            let adb = currentAppContentPath + "/Resources/platform-tools/adb"
            
            //get apks filename from aab
              let aabUrl = URL(fileURLWithPath: aabFilePath)
              let apksFilename = aabUrl.deletingPathExtension()
                  .appendingPathExtension("apks")
                  .lastPathComponent
              
             // print("kkk:\(apksFilename)")
            self.updateProcessMessage("正在转换AppBundle...", error: false)
            let apksFile = self.bundle2apks(aabFilePath, signFilePath:signFilePath,signPwd: signPwd,alias: alias,aliasPwd: aliasPwd,bundlejar: bundlejar,adb: adb,apksFilename: apksFilename)
            if FileManager.default.fileExists(atPath: apksFile.path) {
                // continue
                self.updateProcessMessage("正在安装apks...", error: false)
                self.installApks2Device(apksFilename, bundlejar: bundlejar, adb: adb)
                self.updateProcessMessage("完成", error: false)
                DispatchQueue.main.async {
                    self.btInstall.isEnabled = true
                    self.progressBar.isHidden = true
                    self.progressBar.stopAnimation(sender)

                    self.showInstallFinishDialog(startTime)
                }
            }else{
                self.updateProcessMessage("AppBundle 转换失败！", error: true)
                // error
                DispatchQueue.main.async {
                    self.btInstall.isEnabled = true
                    self.progressBar.isHidden = true
                    self.progressBar.stopAnimation(sender)

                    self.showErrorDialog("AppBundle 转换失败！")
                }
            }
        }
        // shellTest()
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
    
    // 更新进度内容
    func updateProcessMessage(_ message: String,error: Bool) {
        DispatchQueue.main.async {
            self.textProcessMessage.stringValue = message
    //        if error {
    //            self.textProcessMessage.textColor =
    //        }else{
    //            self.textProcessMessage.textColor =
    //        }
        }

        
    }
    
    
    // 设置上次配置
    func setLastConfigs() {
        // init last configs
        let configsDict = ConfigsHelper.getConfigs()
        if !configsDict.isEmpty {
            self.inputSignFilePath.stringValue = configsDict[ConfigsHelper.KEY_SIGN_PATH]!
            self.textSignPwd.stringValue = configsDict[ConfigsHelper.KEY_SING_PWD]!
            self.textAlias.stringValue = configsDict[ConfigsHelper.KEY_ALIAS]!
            self.textAliasPwd.stringValue = configsDict[ConfigsHelper.KEY_ALIAS_PWD]!
        }
    }
    
    // 安卓appbundle
    func bundle2apks(_ aabFilePath: String,signFilePath: String,
                     signPwd: String, alias: String, aliasPwd: String,bundlejar: String,adb: String,apksFilename: String) -> URL {
        let bundle2apksCmd = BundleAppInstallHelper.getBundle2ApksShell(bundlejar,aabFilePath: aabFilePath,
                                                           signFilePath: signFilePath,adbPath: adb,
                                                           signPwd: signPwd, alias: alias, aliasPwd: aliasPwd,apksFilename: apksFilename
        );
        print("Bundle2ApksCommand:\(bundle2apksCmd)")
        BundleAppInstallHelper.shell(bundle2apksCmd);
        return BundleAppInstallHelper.getApksFile(apksFilename)
    }
    
    func installApks2Device(_ apksFilename:String, bundlejar: String,adb: String) {
        let installCmd = BundleAppInstallHelper.getIntallApksShell(bundlejar, adbPath: adb, apksFilename: apksFilename)
        print("installApks2Device Command:\(installCmd)")
        BundleAppInstallHelper.shell(installCmd)
    }
    
    
    
    func shellTest() {

                DispatchQueue.global().async {
                    // working
                    //sleep(5)
                    let adbLog = """
                    List of devices attached
                    R28M22J8MMM    device
                    ce0816081ca9772604    device
                    """
                    
                    let javaLog = """
                    java version "1.8.0_45"
                    Java(TM) SE Runtime Environment (build 1.8.0_45-b14)
                    Java HotSpot(TM) 64-Bit Server VM (build 25.45-b02, mixed mode)
                    """
                    //let count = BundleAppInstallHelper.getDeviceCountFromLog(adbLog)
                    let version = BundleAppInstallHelper.getJavaVersionFromLog(javaLog)
                    DispatchQueue.main.async {
                        // get log file
//                        let downloadsDirectory = self.getLogFile()
//                        do{
//                            let fileContent = try String(contentsOf: downloadsDirectory,encoding: .utf8)
//                            print(fileContent)
//                        }catch{
//                            // do something
//                        }
                        print("设备数：\(version)")
                        
                    }
                }
        
    }

    
    func getLogFile() -> URL {
        return BundleAppInstallHelper.getLogFile()
    }
    
    func getFileContent(_ file: URL) -> String {
        if FileManager.default.fileExists(atPath: file.path) {
            do{
                print("getFileContent:\(file.path)")
                let fileContent = try String(contentsOf: file,encoding: .utf8)
                print("getFileContent:\(fileContent)")
                return fileContent
            }catch{
                // do something
                print(error)
            }
        }else{
            print("getFileContent error: file not found.")
        }
        
        return ""
    }
}

