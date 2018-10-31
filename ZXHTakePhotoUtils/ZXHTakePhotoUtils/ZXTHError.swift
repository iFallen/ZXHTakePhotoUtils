//
//  ZXTHError.swift
//  ZXHTakePhotoUtils
//
//  Created by JuanFelix on 2018/10/30.
//  Copyright © 2018 JuanFelix. All rights reserved.
//

import Foundation

enum ZXTHError: CustomStringConvertible {
    case notAuthorized
    case deviceUnavailable
    case takePhotoFaild
    case error(_ msg: String)
    
    var description: String {
        switch self {
        case .notAuthorized:
            return "未授权,无法使用相机"
        case .deviceUnavailable:
            return "相机不可用,请检查设备"
        case .takePhotoFaild:
            return "拍摄失败,请重试"
        case .error(let msg):
            return msg
        }
    }
}
