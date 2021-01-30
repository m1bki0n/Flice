//
//  ViewController.swift
//  Flice
//
//  Created by Makwan BK on 2021-01-30.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var statusView: UIView!
    
    var session: AVCaptureSession!
    
    var backCamera : AVCaptureDevice!
    var backInput : AVCaptureInput!
    
    var previewLayer : AVCaptureVideoPreviewLayer!
    
    var videoOutput : AVCaptureVideoDataOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainConfiguration()
        startSession()
        
    }

    func mainConfiguration() {
        //TODO:
    }

    func startSession() {
        
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            
            session = AVCaptureSession()
            session.beginConfiguration()
            
            if session.canSetSessionPreset(.photo) {
                session.sessionPreset = .photo
            }
            
            session.automaticallyConfiguresCaptureDeviceForWideColor = true
            
            //Input(s)
            setInputs()
            
            DispatchQueue.main.async {
                self.setPreview()
            }
           
            setOutput()
            
            session.commitConfiguration()
            session.startRunning()
            
        }
        
    }
    
    func setInputs() {
        
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            backCamera = device
        } else {
            fatalError("Failed to get the back camera.")
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError()
        }
        

        
        backInput = deviceInput
        session.addInput(backInput)
        
    }
    
    func setPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.videoGravity = .resizeAspectFill
        
        previewLayer.masksToBounds = true
        previewLayer.frame = view.layer.frame
        
        view.layer.insertSublayer(previewLayer, above: statusView.layer)
        previewLayer.addSublayer(statusView.layer)
        
    }
    
    func setOutput() {
        
        videoOutput = AVCaptureVideoDataOutput()
        let queue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            fatalError()
        }
        
        videoOutput.connection(with: .video)?.isEnabled = true
        
    }
    
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvImageBuffer: cvBuffer)


        let options = [CIDetectorAccuracy : CIDetectorAccuracyLow]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)

        let faces = faceDetector?.features(in: ciImage)

        if let face = faces?.first as? CIFaceFeature {
            print("Found face at \(face.bounds)")

            if face.hasLeftEyePosition {
                    print("Found left eye at \(face.leftEyePosition)")
            }

            if face.hasRightEyePosition {
                print("Found right eye at \(face.rightEyePosition)")
            }

            if face.hasMouthPosition {
                print("Found mouth at \(face.mouthPosition)")
            }

            if face.hasSmile {
                print("SMILEEEEE")
            }
        }
        
    }
    
    
}
