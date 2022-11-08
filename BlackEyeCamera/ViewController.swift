//
//  ViewController.swift
//  BlackEyeCamera
//
//  Created by Arik Segal on 02/11/2022.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    private let photoOutput = AVCapturePhotoOutput()
    private let session = AVCaptureSession()
    private lazy var curtainView: UIView = {
        let size = UIScreen.main.bounds.size
        let btn = UIButton(
            frame: CGRect(
                x: 0,
                y: 0,
                width: size.width,
                height: size.height
            )
        )
        btn.backgroundColor = UIColor.black
        btn.addTarget(self, action: #selector(quit), for: .touchDown)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(curtainView)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            if let _ = setupCaptureSession() {
                takePhoto()
            } else {
                print("Failed to establish capture session")
            }
        } else {
            print("Camera not available")
        }
    }
    /// Will quit the application with animation
    @objc private func quit() {
        DimUnDim.shared.unDim() // Restore normal screen brightness
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        /// Sleep for a while to let the app goes in background
        sleep(2)
        exit(0)
    }

    private func setupCaptureSession() -> AVCaptureSession? {
        session.sessionPreset = .photo
        guard let cameraDevice = AVCaptureDevice.default(for: .video) else {
            print("Unable to fetch default camera")
            return nil
        }
        guard let videoInput = try? AVCaptureDeviceInput(device: cameraDevice) else {
            print("Unable to establish video input")
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
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.startRunning()
        }
        return session
    }
    
    private func takePhoto() {
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) { [weak self] in
            self?.takePhoto()
        }
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // dispose system shutter sound
        AudioServicesDisposeSystemSoundID(1108)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
                print("Processing did finish with no data")
                return
            }
            guard let image = UIImage(data: data) else {
                print("Processing did finish with invalid image data")
                return
            }
            UIImageWriteToSavedPhotosAlbum(
                image,
                self,
                #selector(image(_:didFinishSavingWithError:contextInfo:)),
                nil)
            
            print("Photo taken")
        
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Save error: \(error.localizedDescription)")
        } else {
            print("Saved!")
        }
    }
}