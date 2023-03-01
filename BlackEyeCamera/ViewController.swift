//
//  ViewController.swift
//  BlackEyeCamera
//
//  Created by Arik Segal on 02/11/2022.
//

import AVFoundation
import MediaPlayer
import UIKit

class ViewController: UIViewController {
    private let photoOutput = AVCapturePhotoOutput()
    private let session = AVCaptureSession()
    private let isSwipeToExitEnabled = UserDefaults.standard.bool(forKey: "swipe_to_exit")
    private var hiddenSystemVolumeSlider: UISlider?
    
    private var outputVolumeObserver: NSKeyValueObservation?
    private let audioSession = AVAudioSession.sharedInstance()
    private let cameraDevice = AVCaptureDevice.default(for: .video)
    
    private var systemVolume: Float {
        get {
            return hiddenSystemVolumeSlider?.value ?? -1.0
        }
        set {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) { [weak self] in
                if let self,
                   let slider = self.hiddenSystemVolumeSlider {
                    slider.value = newValue
                    print("System volume changed programmatically to \(newValue)")
                } else {
                    print("Failed to set system volume")
                    assertionFailure()
                }
            }
        }
    }
    
    private lazy var curtainView: UIView = {
        let btn = makeQuitButton(addTargetAction: !isSwipeToExitEnabled)
        return isSwipeToExitEnabled ? addSwipeTo(view: btn) : btn
    }()

    func listenToVolumeButton() {
        do {
            try audioSession.setActive(true)
        } catch {
            return print("Failed to activate audio session: \(error)")
        }

        outputVolumeObserver = audioSession.observe(\.outputVolume) { [weak self] (audioSession, changes) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(100)) { [weak self] in
                print("System Volume: \(String(describing: self?.systemVolume))")
                
                if let self,
                   let device = self.cameraDevice {
                    let newScaleFactor: CGFloat = device.activeFormat.videoMaxZoomFactor * CGFloat(self.systemVolume)
                    print("New desired factor: \(newScaleFactor)")
                } else {
                    print("Failed to update zoom factor: No camera device")
                }
            }
        }
    }
    
    func update(device: AVCaptureDevice, scaleFactor: CGFloat) {
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            device.videoZoomFactor = scaleFactor
        } catch {
            print("Failed to update zoom factor: \(error)")
        }
    }

    private func addSwipeTo(view: UIView) -> UIView {
        let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .right, .left]
        directions.forEach {
            let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(quit))
            recognizer.direction = $0
            view.addGestureRecognizer(recognizer)
        }
        return view
    }
    
    private func makeQuitButton(addTargetAction: Bool) -> UIButton {
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
        if addTargetAction {
            btn.addTarget(self, action: #selector(quit), for: .touchDown)
        }
        return btn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(curtainView)
        setupVolumeControl()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        systemVolume = 0.0
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            if let _ = setupCaptureSession() {
                listenToVolumeButton()
                takePhoto()
            } else {
                print("Failed to establish capture session")
            }
        } else {
            print("Camera not available")
        }
    }
    
    private func setupVolumeControl() {
        let volumeView = MPVolumeView(frame: CGRect(x: -CGFloat.greatestFiniteMagnitude, y:0, width:0, height:0))
        view.addSubview(volumeView)
        hiddenSystemVolumeSlider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
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
        guard let cameraDevice else {
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
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(5)) { [weak self] in
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
