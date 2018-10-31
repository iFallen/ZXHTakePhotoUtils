//
//  ZXHTakePhotoUtils.swift
//  ZXHTakePhotoUtils
//
//  Created by JuanFelix on 2018/10/30.
//  Copyright © 2018 JuanFelix. All rights reserved.
//

import Foundation
import UIKit

class ZXTakePhotoUtils {
    
    /// SHOW
    ///
    /// - Parameters:
    ///   - vc: super vc
    ///   - showConfirm: show confirm view
    ///   - callback: (data,sourceImage,croppedImage)
    static func popshow(upon vc: UIViewController,
                        showConfirm: Bool = true,
                        callback: ZXPhotoCallback?) {
        let nav = UINavigationController.init()
        let aVC = ZXHTakePhotoViewController()
        aVC.callBack = callback
        aVC.showConfirm = showConfirm
        nav.setViewControllers([aVC], animated: true)
        vc.present(nav, animated: true, completion: nil)
    }
}
