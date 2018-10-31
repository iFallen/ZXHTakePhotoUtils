//
//  ZXHConfirmViewController.swift
//  ZXHTakePhotoUtils
//
//  Created by JuanFelix on 2018/10/30.
//  Copyright © 2018 JuanFelix. All rights reserved.
//

import UIKit
typealias ZXEmptyCallback = () -> Void

class ZXHConfirmViewController: UIViewController {

    var callBack: ZXEmptyCallback?
    var image: UIImage?
    @IBOutlet weak var imgPreView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.imgPreView.image = image
    }
    
    @IBAction func reTakeAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func confirmAction(_ sender: Any) {
        self.dismiss(animated: true) {
            self.callBack?()
        }
    }
}
