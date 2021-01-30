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
    @IBOutlet weak var statusEmoji: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    private var blurView : UIView! {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurredView = UIVisualEffectView(effect: blurEffect)
        
        blurredView.frame = statusView.bounds
        
        return blurredView
    }
    
    var session: AVCaptureSession!
    
    var backCamera : AVCaptureDevice!
    var backInput : AVCaptureInput!
    
    var previewLayer : AVCaptureVideoPreviewLayer!
    
    var videoOutput : AVCaptureVideoDataOutput!
    
    enum EmojiStatus {
        case happy
        case eyeClosed
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainConfiguration()
        startSession()
        
    }
    
    func mainConfiguration() {
        
        title = "Flice"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.triangle.2.circlepath.camera"), style: .plain, target: self, action: #selector(flipCamera))
        
        
        statusView.clipsToBounds = true
        statusView.layer.cornerRadius = 15
        statusView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        statusEmoji.text = "🧐"
        
        statusLabel.text = "Searching for your status"
        statusLabel.font = .init(descriptor: UIFont.systemFont(ofSize: 22, weight: .medium).fontDescriptor.withDesign(.rounded)!, size: 22)
        
        statusView.insertSubview(blurView, at: 0)
        
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
        previewLayer.addSublayer(blurView.layer)
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
        
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.connection(with: .video)?.isEnabled = true
        
    }
    
    func imageFromSampleBuffer(_ sampleBuffer : CMSampleBuffer) -> UIImage {
        
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        let imageRef = context?.makeImage()
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let resultImage: UIImage = UIImage(cgImage: imageRef!)
        
        return resultImage
        
    }
    
    func setUIChanges(emoji: String, text: String) {
        statusEmoji.text = emoji
        statusLabel.text = text
    }
    
    @objc func flipCamera() {
        let ac = UIAlertController(title: "Soon", message: "In next update, you'll be able to switch between front and rear cameras.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        present(ac, animated: true, completion: nil)
    }
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let image = self.imageFromSampleBuffer(sampleBuffer)
        
        let ciImage = CIImage(image: image)!
        
        
        let options = [CIDetectorAccuracy : CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)
        
        let faces = faceDetector?.features(in: ciImage, options: [CIDetectorSmile : true, CIDetectorEyeBlink : true])
        
        for face in faces as! [CIFaceFeature] {
            
            if face.hasSmile {
                DispatchQueue.main.async { [unowned self] in
                    setUIChanges(emoji: "😊", text: "Happy me!")
                }
            } else if face.leftEyeClosed && face.rightEyeClosed {
                DispatchQueue.main.async { [unowned self] in
                    setUIChanges(emoji: "🙈", text: "Eyes Closed")
                }
            } else {
                DispatchQueue.main.async { [unowned self] in
                    setUIChanges(emoji: "🧐", text: "Searching for your status")
                }
            }
        }
    }
    
    
}
