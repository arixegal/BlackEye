//
//  ViewController.swift
//  BlackEye
//
//  Created by Arik Segal on 26/07/2022.
//

import UIKit
import AVFoundation

final class ViewController: UIViewController {
    private let photoOutput = AVCapturePhotoOutput()
    private let session = AVCaptureSession()

    private lazy var curtainView: UIView = {
        let bounds = UIScreen.main.bounds
        let btn = UIButton(
            frame: CGRect(
                x: 0,
                y: 0,
                width: bounds.self.width,
                height: bounds.size.height
            )
        )
        btn.backgroundColor = UIColor.black
        btn.addTarget(self, action: #selector(unDimAndQuit), for: .touchDown)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(curtainView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            if let _ = setupCaptureSession() {
                takePhoto(settings: nil)
            } else {
                print("Failed to establish capture session")
            }
        } else {
            print("Camera not available")
        }
    }
        
    private func setupCaptureSession() -> AVCaptureSession? {
        session.sessionPreset = .photo
                
        guard let cameraDevice = AVCaptureDevice.default(for: .video) else {
            return nil
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: cameraDevice) else {
            return nil
        }
        
        session.beginConfiguration()
            
            session.sessionPreset = AVCaptureSession.Preset.photo

            guard session.canAddInput(videoInput) else {
                print("Unable to add videoInput to captureSession")
                return nil
            }
            session.addInput(videoInput)

            guard session.canAddOutput(photoOutput) else {
                print("Unable to add videoOutput to captureSession")
                return nil
            }
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
                    
        session.commitConfiguration()

        session.startRunning()
        
        return session
        
    }
    
    private func takePhoto(settings: AVCapturePhotoSettings?) {
        guard let finalSettings: AVCapturePhotoSettings = settings ?? createPhotoSettings() else {
            print("Failed to create photo settings")
            return
        }
        photoOutput.capturePhoto(with: finalSettings, delegate: self)
        
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {[weak self] in
            self?.takePhoto(settings: settings)
        }
    }
    
    private func createPhotoSettings() -> AVCapturePhotoSettings? {
        let settings = AVCapturePhotoSettings()
        if settings.availablePreviewPhotoPixelFormatTypes.count > 0 {
            settings.previewPhotoFormat = [ kCVPixelBufferPixelFormatTypeKey as String : settings.availablePreviewPhotoPixelFormatTypes.first!]
        }
        return settings
    }
    
    @objc private func unDimAndQuit() {
        DimUnDim.shared.unDim()
        quit()
    }

    /// Will quit the application with animation
    private func quit() {
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        /// Sleep for a while to let the app goes in background
        sleep(2)
        exit(0)
    }    
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            return
        }
        
        guard let image = UIImage(data: data) else {
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        print("Photo taken")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
            // dispose system shutter sound
            AudioServicesDisposeSystemSoundID(1108)
    }
}
