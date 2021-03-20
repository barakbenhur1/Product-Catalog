//
//  BarcdeScanerPopup.swift
//  ProductCataloger
//
//  Created by Interactech on 20/03/2021.
//

import AVFoundation
import UIKit

class BarcdeScanerPopup: UIView {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    ///params
    var scanComplition: ((_ code: String?) -> ())?
    
    private var containerView: UIView!
    
    @discardableResult
    static func showOn(view: UIView) -> BarcdeScanerPopup {
        
        let barcodeScanView = BarcdeScanerPopup(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        
        barcodeScanView.containerView = UIView(frame: view.frame)
        barcodeScanView.containerView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.86)
        
        let closeButton = UIButton(frame: CGRect(x: 20, y: 64, width: 60, height: 40))
        closeButton.setTitle("close", for: .normal)
        closeButton.addTarget(barcodeScanView, action: #selector(close), for: .touchUpInside)
        
        barcodeScanView.containerView.addSubview(closeButton)
        
        barcodeScanView.containerView.addSubview(barcodeScanView)
        barcodeScanView.center = barcodeScanView.containerView.center
        
        view.addSubview(barcodeScanView.containerView)
        
        barcodeScanView.layer.cornerRadius = 20
        barcodeScanView.layer.borderWidth = 0.5
        barcodeScanView.layer.borderColor = UIColor.yellow.cgColor
        
        barcodeScanView.initCamera()
        
        return barcodeScanView
    }
    
    @objc private func close() {
        containerView.removeFromSuperview()
    }
    
    private func initCamera() {
        
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        circleView.layer.cornerRadius = 5
        circleView.backgroundColor = .green
        
        backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.cornerRadius = 20
        layer.addSublayer(previewLayer)
        previewLayer.addSublayer(circleView.layer)
        circleView.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
        
        let timer = Timer(timeInterval: 0.3, repeats: true) { (timer) in
            UIView.animate(withDuration: 0.3) {
                circleView.isOpaque = !circleView.isOpaque
                
                circleView.alpha = circleView.isOpaque ? 0 : 1
            }
        }
        
        RunLoop.main.add(timer, forMode: .common)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    func failed() {
        scanComplition?(nil)
        captureSession = nil
    }
    
    func found(code: String) {
        print(code)
    }
}

extension BarcdeScanerPopup: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        var code: String? = nil
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
            code = stringValue
        }
        
        scanComplition?(code)
        
        close()
    }
}
