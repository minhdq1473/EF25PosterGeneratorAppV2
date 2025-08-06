//
//  CameraVC.swift
//  EF25PosterGenerator2.0
//
//  Created by iKame Elite Fresher 2025 on 4/8/25.
//

import UIKit
import AVFoundation

protocol CameraVCDelegate: AnyObject {
    func cameraVC(_ controller: CameraVC, didCapture image: UIImage)
}

class CameraVC: UIViewController {
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var cameraView: UIView!
    
    weak var delegate: CameraVCDelegate?

    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let captureSession = AVCaptureSession()
    
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    private var currentInput: AVCaptureDeviceInput?
    private var isUsingFrontCamera = false
    private var flashMode: AVCaptureDevice.FlashMode = .auto
    
    private let sessionQueue = DispatchQueue(label: "cameraQueue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        // Do any additional setup after loading the view.
    }
    
    private func setupCamera() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        cameraView.layer.addSublayer(previewLayer)
        
        sessionQueue.async {
            self.setupDevice(position: .back)
            self.captureSession.startRunning()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        previewLayer.cornerRadius = cameraView.layer.cornerRadius
//        sessionQueue.async { [weak self] in
//            if self?.captureSession.isRunning == false {
//                self?.captureSession.startRunning()
//            }
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sessionQueue.async { [weak self] in
            if self?.captureSession.isRunning == true {
                self?.captureSession.stopRunning()
            }
        }
    }
    
    private func setupDevice(position: AVCaptureDevice.Position) {
        captureSession.beginConfiguration()
        
        if let currentInput = currentInput {
            captureSession.removeInput(currentInput)
        }
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Failed to get camera input")
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            currentDevice = device
            currentInput = input
        }
        
        if captureSession.outputs.isEmpty, captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    
    @IBAction func tapClose(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func tapFlash(_ sender: UIButton) {
        switch flashMode {
        case .off:
            flashBtn.setImage(UIImage(named: "icFlashAuto"), for: .normal)
            flashMode = .auto
        case .on:
            flashBtn.setImage(UIImage(named: "icFlashOff"), for: .normal)
            flashMode = .off
        default:
            flashBtn.setImage(UIImage(named: "icFlashOn"), for: .normal)
            flashMode = .on
        }        
    }
    
    @IBAction func tapPhoto(_ sender: UIButton) {
        
    }
    
    @IBAction func tapCapture(_ sender: UIButton) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @IBAction func tapFlip(_ sender: UIButton) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.isUsingFrontCamera.toggle()
            let position: AVCaptureDevice.Position = self.isUsingFrontCamera ? .front : .back
            self.setupDevice(position: position)
        }
    }
}

extension CameraVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("Failed to capture photo")
            return
        }
        
        delegate?.cameraVC(self, didCapture: image)
        dismiss(animated: true)
    }
}
