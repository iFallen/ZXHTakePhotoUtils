//
//  ViewController.swift
//  ZXHTakePhotoUtils
//
//  Created by JuanFelix on 2018/10/30.
//  Copyright © 2018 JuanFelix. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imgCrop: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func takeAction(_ sender: Any) {
        ZXTakePhotoUtils.popshow(upon: self, showConfirm: true) { (data, sourceImage, cropImage) in
            //self.imgCrop.image = sourceImage
            self.imgCrop.image = cropImage
        }
    }
    
}

