//
//  ConfigsHelper.swift
//  androidtools
//
//  Created by didikee on 7/27/20.
//  Copyright © 2020 didikee. All rights reserved.
//

import Foundation

class ConfigsHelper{
    static let KEY_APP_INSTALL_DICT = "app_install"
    static let KEY_SIGN_PATH = "key_sign_path"
    static let KEY_SING_PWD = "key_sign_pwd"
    static let KEY_ALIAS = "key_alias"
    static let KEY_ALIAS_PWD = "key_alias_pwd"
    
    static func setConfigs(_ signPath: String,signPwd: String,alias: String,aliasPwd: String ){
        if signPath.isEmpty || signPwd.isEmpty || alias.isEmpty || aliasPwd.isEmpty {
            print("一个或者多个参数为空")
            return
        }
        let userDefaults = UserDefaults.standard
        
        var dict:[String:String] = [:]
        dict[KEY_SIGN_PATH] = signPath
        dict[KEY_SING_PWD] = signPwd
        dict[KEY_ALIAS] = alias
        dict[KEY_ALIAS_PWD] = aliasPwd
        userDefaults.set(dict, forKey: KEY_APP_INSTALL_DICT)
        
        print("数据已经保存")
    }
    
    static func getConfigs()->[String:String]{
        let dict = UserDefaults.standard.dictionary(forKey: KEY_APP_INSTALL_DICT)
        if dict == nil {
            return [:]
        } else {
            return dict as! [String:String]
        }
        
    }

}
