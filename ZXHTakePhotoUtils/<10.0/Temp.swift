
import UIKit
import AVFoundation

//use AVCaptureStillImageOutput replace AVCapturePhotoOutput
class ZXHIDAuthorizeViewController: ZXUIViewController {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var scanFrame: UIView!
    @IBOutlet weak var lbTips: UILabel!
    
    @IBOutlet weak var controlView: UIView!
    
    //Animation Layer
    var session:AVCaptureSession?
    var videoInput: AVCaptureDeviceInput?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var showIntro = true
    
    static func popshow(upon vc: UIViewController, showIntro: Bool = true) {
        let nav = UINavigationController.init()
        let aVC = ZXHIDAuthorizeViewController()
        if showIntro {
            let introVC = ZXHAuthorizeIntroViewController()
            introVC.callback = {
                nav.setViewControllers([aVC], animated: true)
            }
            nav.setViewControllers([introVC], animated: true)
        } else {
            nav.setViewControllers([aVC], animated: true)
        }
        vc.present(nav, animated: true, completion: nil)
    }
    //
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.hidesBottomBarWhenPushed = true
        self.fd_prefersNavigationBarHidden = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not init")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = "拍摄身份证"
        self.scanFrame.backgroundColor = UIColor.clear
        self.zx_navbarAddBarButtonItems(imageNames: ["zx-close-icon"], useOriginalColor: false, at: .left)
    }
    
    override func zx_leftBarButtonAction(index: Int) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkAuthorization { (status) in
            if status == .authorized || status == .notDetermined {
                self.beginScanning()
            }else{
                ZXHUD.showFailure(in: self.view, text: "未授权,无法使用相机", delay: ZX_DELAY_INTERVAL)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.stopScan()
    }
    
    //MARK: - take photo
    fileprivate var isTaking = false
    @IBAction func takePhotoAction(_ sender: UIButton) {
        if self.isCameraAvailable() {
            guard let videoConnection = self.stillImageOutput?.connection(withMediaType: AVMediaTypeVideo) else {
                ZXHUD.showFailure(in: self.view, text: "拍摄失败,请重试", delay: ZXHUD_MBDELAY_TIME)
                return
            }
            if isTaking {
                return
            }
            isTaking = true
            let scanCrop = self.getScanCrop(toRect: self.scanFrame.frame, readerViewBounds: self.previewView.bounds)
            self.stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (buffer, error) in
                if let buffer = buffer, let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer), let image = UIImage(data: data) {
                    //print("image size \(NSStringFromCGSize(image.size))")
                    let image = UIImage.fixOrientation(image)!
                    let cgImageCorpped = image.cgImage?.cropping(to: CGRect(x: scanCrop.origin.x * image.size.width, y: scanCrop.origin.y * image.size.height, width: scanCrop.size.width * image.size.width, height: scanCrop.size.height * image.size.height))
                    DispatchQueue.main.async(execute: {
                        self.showConfirm(image: UIImage(cgImage: cgImageCorpped!))
                        self.isTaking = false
                    })
                } else {
                    ZXHUD.showFailure(in: self.view, text: "拍摄失败,请重试", delay: ZXHUD_MBDELAY_TIME)
                    self.isTaking = false
                }
            })
        } else {
            ZXHUD.showFailure(in: self.view, text: "相机不可用,请检查设备", delay: ZXHUD_MBDELAY_TIME)
        }
    }
}

extension ZXHIDAuthorizeViewController {
    func checkAuthorization(completion:((_ status:AVAuthorizationStatus) -> Void)?) {
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        switch status {
        case .authorized:
            completion?(.authorized)
        case .denied:
            completion?(.denied)
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted) in
                DispatchQueue.main.async {
                    if granted{
                        completion?(.authorized)
                    } else {
                        completion?(.denied)
                    }
                }
            })
        case .restricted:
            completion?(.restricted)
        }
    }
    
    func stopScan() {
        if let session = self.session,session.isRunning {
            session.stopRunning()
        }
    }
    
    func restartScan() {
        if let session = session {
            if session.isRunning { return }
            session.startRunning()
        }
    }
    
    func beginScanning() {
        if session == nil {
            guard let backCamera = AVCaptureDevice.backCamera() else {
                ZXHUD.showFailure(in: self.view, text: "相机不可用,请检查设备", delay: ZXHUD_MBDELAY_TIME)
                return
            }
            do {
                self.videoInput = try AVCaptureDeviceInput(device: backCamera)
                self.stillImageOutput = AVCaptureStillImageOutput()
                self.stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG,
                                                         AVVideoWidthKey: self.previewView.bounds.width,
                                                         AVVideoHeightKey: self.previewView.bounds.height]
                self.session = AVCaptureSession()
                self.session?.sessionPreset = AVCaptureSessionPresetHigh
                
                self.session?.addInput(videoInput)
                self.session?.addOutput(stillImageOutput)
                
                if let layer = AVCaptureVideoPreviewLayer.init(session: self.session!) {
                    layer.videoGravity = AVLayerVideoGravityResizeAspectFill
                    layer.frame = self.previewView.bounds
                    self.previewView.layer.insertSublayer(layer, at: 0)
                }
                //添加漏空遮罩层
                self.addMaskLayer()
            } catch  {
                ZXAlertUtils.showAlert(withTitle: "提示", message: "相机不可用")
                return
            }
        }
        self.restartScan()
    }
    //MARK: - 漏空遮罩层
    fileprivate func addMaskLayer() {
        //let bounds = UIScreen.main.bounds
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
    
    fileprivate func getScanCrop(toRect rect:CGRect,readerViewBounds bounds:CGRect) -> CGRect {
        let x = (bounds.size.width - rect.size.width) / 2 / bounds.size.width
        let y = rect.origin.y / bounds.size.height
        let width = rect.size.width / bounds.size.width
        let height = rect.size.height / bounds.size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    fileprivate func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    fileprivate func showConfirm(image: UIImage) {
        let aVC = ZXHIDConfirmViewController()
        aVC.image = image
        self.navigationController?.pushViewController(aVC, animated: true)
    }
}


extension AVCaptureDevice {
    static func camera(with position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        guard let devices = self.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] else {
            return nil
        }
        for device in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    static func frontCamera() -> AVCaptureDevice? {
        return self.camera(with: .front)
    }
    
    static func backCamera() -> AVCaptureDevice? {
        return self.camera(with: .back)
    }
}
