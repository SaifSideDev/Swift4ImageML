//
//  CameraViewController.swift
//  ImageML
//
//  Created by Saif Khan on 3/12/18.
//  Copyright © 2018 SaifSide Inc. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState {
    case off
    case on
}

class CameraViewController: UIViewController {
    
    // MARK: - IBOutlet
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var helperView: RoundedShadowView!
    @IBOutlet weak var imageRecognizedView: RoundedShadowView!
    @IBOutlet weak var flashButton: RoundedShadowButton!
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    @IBOutlet weak var imageIdentifiedLabel: UILabel!
    @IBOutlet weak var accuracyPercentageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Private Constants
    fileprivate let defaults = UserDefaults.standard
    
    // MARK: - Private Variables
    fileprivate var photoData: Data?
    fileprivate var flashState: FlashState = .off
    
    // MARK: - AVFoundation Variables
    
    // Control Real-Time Camera
    fileprivate var captureSession: AVCaptureSession!
    
    // Capture Still Image
    fileprivate var cameraOutput: AVCapturePhotoOutput!
    
    // Show Camera View to Capture Image
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer!

    // MARK: - AVSpeechSynthesizer
    fileprivate var speechSynthesizer = AVSpeechSynthesizer()
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.speechSynthesizer.delegate = self
        
        self.dismissTutorialHelper()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ...Instantiate Capture Session
        self.setupAVCaptureSession()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Fit Preview Layer inside Camera View
        self.previewLayer.frame = self.cameraView.bounds
    }
    
    // MARK: - IBAction
    @IBAction func didTapFlashButton(_ sender: UIButton) {
       self.configureFlashState()
    }
    
    // MARK: - Private Methods
    @objc fileprivate func didTapCameraView() {
        // Disable User Interaction
        self.cameraView.isUserInteractionEnabled = false
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        
        self.imageRecognizedView.isHidden = false
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType, kCVPixelBufferWidthKey as String: 160.0, kCVPixelBufferHeightKey as String: 160.0] as [String : Any]
        settings.previewPhotoFormat = previewFormat
        // If Above Doesn't Work, Use settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        
        if self.flashState == .off {
            settings.flashMode = .off
            
        } else {
            settings.flashMode = .on
        }
        
        self.cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    fileprivate func resultsMethod(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else { return }
        for classification in results {
            if classification.confidence < 0.5 {
                self.imageIdentifiedLabel.numberOfLines = 0
                let unidentifiedObjectMessage = "Sorry, I don't know what that is.\nI'm still learning..."
                self.imageIdentifiedLabel.text = unidentifiedObjectMessage
                self.synthesizeSpeech(string: unidentifiedObjectMessage)
                self.accuracyPercentageLabel.text = ""
                self.resetView()
                break
            } else {
                let identification = classification.identifier
                let accuracyPercentage = Int(classification.confidence * 100)
                 self.imageIdentifiedLabel.text = classification.identifier
                self.accuracyPercentageLabel.text = "I am \(accuracyPercentage)% sure!"
                let completeSentence = "I think this is a \(identification) and I'm \(accuracyPercentage) percent confident!"
                self.synthesizeSpeech(string: completeSentence)
                self.resetView()
                break
            }
        }
    }
    
    fileprivate func setupAVCaptureSession() {
        // Create Tap Gesture Recognizer
        let cameraViewTap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        cameraViewTap.numberOfTapsRequired = 2
        
        // Initiate and Configure Capture Session
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        self.captureSession = AVCaptureSession()
        self.captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if self.captureSession.canAddInput(input) == true {
                self.captureSession.addInput(input)
            }
            
            self.cameraOutput = AVCapturePhotoOutput()
            if self.captureSession.canAddOutput(self.cameraOutput) == true {
                captureSession.addOutput(self.cameraOutput!)
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
                // Maintain Aspect Ration without Distorting
                self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                // Orientation Configuration
                self.previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                self.cameraView.layer.addSublayer(self.previewLayer!)
                self.cameraView.addGestureRecognizer(cameraViewTap)
                self.captureSession.startRunning()
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    fileprivate func configureFlashState() {
        switch flashState {
        // When the Flash is ON
        case .off:
            self.flashButton.setTitle("Flash ON", for: .normal)
            self.flashButton.setTitleColor(UIColor.blue, for: .normal)
            self.flashState = .on
            
        // When the Flash is OFF
        case .on:
            self.flashButton.setTitle("Flash OFF", for: .normal)
            self.flashButton.setTitleColor(UIColor.lightGray, for: .normal)
            self.flashState = .off
        }
    }
    
    fileprivate func synthesizeSpeech(string: String) {
        let speechUtterance = AVSpeechUtterance(string: string)
        self.speechSynthesizer.speak(speechUtterance)
    }
    
    // Dismiss Tutorial Helper View
    fileprivate func dismissTutorialHelper() {
        let delay = 4.0 //secs
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            UIView.transition(with: self.helperView, duration: 0.5, options: .transitionCrossDissolve, animations: {
                self.helperView.isHidden = true
            })
        }
    }
    
    // Dismiss Image Identifier UIView after _ Seconds
    fileprivate func resetView() {
        let delay = 5.0 //secs
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            UIView.transition(with: self.imageRecognizedView, duration: 0.5, options: .transitionCrossDissolve, animations: {
                self.imageRecognizedView.isHidden = true
                self.imageIdentifiedLabel.text = "Hmm..."
                self.accuracyPercentageLabel.text = "I'm thinking..."
            })
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error.localizedDescription)
        } else {
            // Set Photo Data to Outputted Photo
            self.photoData = photo.fileDataRepresentation()
            
            // Integrate Machine Learning Vision CoreML Model
            do {
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: self.photoData!)
                try handler.perform([request])
            } catch {
                debugPrint(error.localizedDescription)
            }
            
            // Convert Photo Data to UIImage
            let image = UIImage(data: self.photoData!)
            // Set Image in ImageView
            self.captureImageView.image = image
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension CameraViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Re-enable User Interaction
        self.cameraView.isUserInteractionEnabled = true
        self.activityIndicator.stopAnimating()
    }
}
