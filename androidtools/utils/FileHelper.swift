//
//  FileHelper.swift
//  androidtools
//
//  Created by didikee on 7/24/20.
//  Copyright © 2020 didikee. All rights reserved.
//

import Foundation
import Darwin

class FileHelper {
    // 检测Android文件夹是否存在，不存在就创建
    static func checkInitAndroidFodler() -> Bool{
        var androidFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        androidFolder.appendPathComponent("Android", isDirectory: true)
        if !FileManager.default.fileExists(atPath: androidFolder.path) {
            do {
                try FileManager.default.createDirectory(atPath: androidFolder.path, withIntermediateDirectories: true, attributes: nil)
            } catch  {
                print("FileHelper.checkAndroidFodler error:\(error.localizedDescription)")
            }
        }
        return FileManager.default.fileExists(atPath: androidFolder.path)
    }
}
