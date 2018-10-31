//
//  AVCaptureDevice+ZX.swift
//  ZXHTakePhotoUtils
//
//  Created by JuanFelix on 2018/10/30.
//  Copyright © 2018 JuanFelix. All rights reserved.
//

import Foundation
import AVFoundation

extension AVCaptureDevice {
    static func camera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        var devices: [AVCaptureDevice] = []
        if #available(iOS 10.2, *) {
            devices = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInDualCamera], mediaType: AVMediaType.video, position: position).devices
        } else {
            devices = self.devices(for: AVMediaType.video)
        }
        for device in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    static func frontCamera() -> AVCaptureDevice? {
        return camera(with: .front)
    }
    
    static func backCamera() -> AVCaptureDevice? {
        return camera(with: .back)
    }
    
    static func checkAuthorization(completion:((_ status:AVAuthorizationStatus) -> Void)?) {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status {
        case .authorized:
            completion?(.authorized)
        case .denied:
            completion?(.denied)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
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

}
