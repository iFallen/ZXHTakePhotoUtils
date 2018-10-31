//
//  ZXHTakePhotoViewController.swift
//  ZXHTakePhotoUtils
//
//  Created by JuanFelix on 2018/10/30.
//  Copyright © 2018 JuanFelix. All rights reserved.
//

import UIKit
import AVFoundation

typealias ZXPhotoCallback = (_ data: Data, _ sourceImage: UIImage, _ croppedImage: UIImage?) -> Void

class ZXHTakePhotoViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var scanFrame: UIView!
    @IBOutlet weak var lbTips: UILabel!
    
    fileprivate var session:AVCaptureSession?
    fileprivate var videoInput: AVCaptureDeviceInput?
    fileprivate var stillImageOutput: AVCapturePhotoOutput?
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    
    var showConfirm = true
    var callBack: ZXPhotoCallback?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "拍摄"
        self.scanFrame.backgroundColor = UIColor.clear
        let leftBarButton = UIBarButtonItem.init(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(dismissAction))
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    @objc func dismissAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AVCaptureDevice.checkAuthorization { (status) in
            if status == .authorized || status == .notDetermined {
                self.beginRecording()
            } else {
                self.showError(type: .notAuthorized)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.stopRecording()
    }
    fileprivate var isTaking = false
    //MARK: - Take Photo
    @IBAction func takePhotoAction(_ sender: UIButton) {
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized {
            if isTaking {
                return
            }
            isTaking = true
            let settings = AVCapturePhotoSettings(format: [
                AVVideoCodecKey:AVVideoCodecType.jpeg])
            //let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
            //let previewFormat = [
            //    kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            //    kCVPixelBufferWidthKey as String: self.previewView.bounds.width,
            //    kCVPixelBufferHeightKey as String: self.previewView.bounds.height
            //    ] as [String : Any]
            //settings.previewPhotoFormat = previewFormat
            //TAKE
            self.stillImageOutput?.capturePhoto(with: settings, delegate: self)
        } else {
            self.showError(type: .notAuthorized)
        }
    }
    
    fileprivate func showError(type: ZXTHError) {
        let alert = UIAlertController.init(title: "提示", message: type.description, preferredStyle: .alert)
        let action = UIAlertAction.init(title: "确定", style: .default, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
}

extension ZXHTakePhotoViewController {
    //MARK: - 漏空遮罩层
    fileprivate func addMaskLayer() {
        let bounds = self.previewView.bounds
        let maskLayer = CALayer()
        maskLayer.frame = bounds
        maskLayer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6).cgColor
        let empty = CAShapeLayer()
        let frame = self.scanFrame.frame
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: 0)
        path.append(UIBezierPath(roundedRect: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height), cornerRadius: 0).reversing())
        empty.path = path.cgPath
        maskLayer.mask = empty
        self.previewView.layer.insertSublayer(maskLayer, below: self.lbTips.layer)
    }
    
    /// MARK: - 裁剪尺寸
    fileprivate func getScanCrop(toRect rect:CGRect,
                                 readerViewBounds bounds:CGRect) -> CGRect {
        let x = (bounds.size.width - rect.size.width) / 2 / bounds.size.width
        let y = rect.origin.y / bounds.size.height
        let width = rect.size.width / bounds.size.width
        let height = rect.size.height / bounds.size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

extension ZXHTakePhotoViewController {
    
    func stopRecording() {
        if let session = self.session,session.isRunning {
            session.stopRunning()
        }
    }
    
    func restartRecording() {
        if let session = session {
            if session.isRunning { return }
            session.startRunning()
        }
    }
    
    func beginRecording() {
        self.isTaking = false
        if session == nil {
            guard let backCamera = AVCaptureDevice.backCamera() else {
                self.showError(type: .deviceUnavailable)
                return
            }
            do {
                let settings = AVCapturePhotoSettings(format: [
                    AVVideoCodecKey:AVVideoCodecType.jpeg])
                //let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
                //let previewFormat = [
                //    kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                //    kCVPixelBufferWidthKey as String: self.previewView.bounds.width,
                //    kCVPixelBufferHeightKey as String: self.previewView.bounds.height
                //    ] as [String : Any]
                //settings.previewPhotoFormat = previewFormat
                
                self.videoInput = try AVCaptureDeviceInput(device: backCamera)
                self.stillImageOutput = AVCapturePhotoOutput()
                self.stillImageOutput?.photoSettingsForSceneMonitoring = settings
                
                self.session = AVCaptureSession()
                self.session?.sessionPreset = AVCaptureSession.Preset.high
                self.session?.addInput(videoInput!)
                self.session?.addOutput(stillImageOutput!)
                let layer = AVCaptureVideoPreviewLayer.init(session: self.session!)
                layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                layer.frame = self.previewView.bounds
                self.previewView.layer.insertSublayer(layer, at: 0)
                //添加漏空遮罩层
                self.addMaskLayer()
            } catch  {
                self.showError(type: .deviceUnavailable)
                return
            }
        }
        self.restartRecording()
    }
}


extension ZXHTakePhotoViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            self.showError(type: .error(error.localizedDescription))
            print(error.localizedDescription)
            self.isTaking = false
        } else {
            self.takeEndAction(img: photo.fileDataRepresentation())
        }
    }
    
    fileprivate func takeEndAction(img data: Data?) {
        if let data = data, let sImage = UIImage(data: data) {
            let image = sImage.fixOrientation()
            var cropImage: UIImage?
            let scanCrop = self.getScanCrop(toRect: self.scanFrame.frame, readerViewBounds: self.previewView.bounds)
            if let cgImageCorpped = image.cgImage?.cropping(to: CGRect(x: scanCrop.origin.x * image.size.width, y: scanCrop.origin.y * image.size.height, width: scanCrop.size.width * image.size.width, height: scanCrop.size.height * image.size.height)) {
                cropImage = UIImage.init(cgImage: cgImageCorpped)
            }
            DispatchQueue.main.async(execute: {
                if self.showConfirm {
                    if let nav = self.navigationController {
                        let cVC = ZXHConfirmViewController()
                        cVC.image = cropImage
                        cVC.callBack = {
                            self.callBack?(data, image, cropImage)
                        }
                        nav.pushViewController(cVC, animated: true)
                    } else {
                        self.isTaking = false
                        self.callBack?(data, image, cropImage)
                    }
                } else {
                    self.isTaking = false
                }
            })
        } else {
            self.isTaking = false
        }
    }
}

