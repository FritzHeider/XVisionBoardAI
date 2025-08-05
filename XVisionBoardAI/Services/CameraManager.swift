//
//  CameraManager.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation
import AVFoundation
import SwiftUI
import Vision

@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var session = AVCaptureSession()
    @Published var preview: AVCaptureVideoPreviewLayer?
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false
    @Published var errorMessage: String?
    @Published var faceDetected = false
    @Published var faceQuality: FaceQuality = .unknown
    
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    enum FaceQuality {
        case unknown
        case poor
        case good
        case excellent
        
        var description: String {
            switch self {
            case .unknown: return "Position your face in the circle"
            case .poor: return "Move closer and look directly at camera"
            case .good: return "Good! Hold steady"
            case .excellent: return "Perfect! Ready to capture"
            }
        }
        
        var color: Color {
            switch self {
            case .unknown: return .gray
            case .poor: return .red
            case .good: return .yellow
            case .excellent: return .green
            }
        }
    }
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    // MARK: - Permissions
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupCamera()
        case .notDetermined:
            requestPermission()
        case .denied, .restricted:
            isAuthorized = false
            errorMessage = "Camera access is required to take selfies"
        @unknown default:
            isAuthorized = false
        }
    }
    
    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.setupCamera()
                } else {
                    self?.errorMessage = "Camera access denied"
                }
            }
        }
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        
        // Add video input (front camera for selfies)
        guard let frontCamera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {
            DispatchQueue.main.async {
                self.errorMessage = "Front camera not available"
            }
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to setup camera input: \(error.localizedDescription)"
            }
            return
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        
        // Add video output for face detection
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        // Configure session quality
        session.sessionPreset = .photo
        
        session.commitConfiguration()
        
        DispatchQueue.main.async {
            self.preview = AVCaptureVideoPreviewLayer(session: self.session)
            self.preview?.videoGravity = .resizeAspectFill
        }
    }
    
    // MARK: - Camera Control
    
    func startSession() {
        sessionQueue.async { [weak self] in
            if !(self?.session.isRunning ?? true) {
                self?.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            if self?.session.isRunning ?? false {
                self?.session.stopRunning()
            }
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto() {
        guard !isCapturing else { return }
        
        isCapturing = true
        errorMessage = nil
        
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        
        // Enable flash if needed
        if photoOutput.supportedFlashModes.contains(.auto) {
            settings.flashMode = .auto
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func retakePhoto() {
        capturedImage = nil
        faceDetected = false
        faceQuality = .unknown
    }
    
    // MARK: - Face Detection
    
    private func detectFaces(in sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            DispatchQueue.main.async {
                self?.processFaceDetectionResults(request.results)
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Face detection error: \(error)")
        }
    }
    
    private func processFaceDetectionResults(_ results: [VNObservation]?) {
        guard let faceObservations = results as? [VNFaceObservation] else {
            faceDetected = false
            faceQuality = .unknown
            return
        }
        
        if let face = faceObservations.first {
            faceDetected = true
            
            // Analyze face quality
            let confidence = face.confidence
            let boundingBox = face.boundingBox
            
            // Check if face is well-positioned and clear
            let isWellPositioned = boundingBox.width > 0.3 && boundingBox.height > 0.3
            let isCentered = abs(boundingBox.midX - 0.5) < 0.2 && abs(boundingBox.midY - 0.5) < 0.2
            
            if confidence > 0.9 && isWellPositioned && isCentered {
                faceQuality = .excellent
            } else if confidence > 0.7 && isWellPositioned {
                faceQuality = .good
            } else if confidence > 0.5 {
                faceQuality = .poor
            } else {
                faceQuality = .unknown
            }
        } else {
            faceDetected = false
            faceQuality = .unknown
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            DispatchQueue.main.async {
                self.errorMessage = "Photo capture failed: \(error.localizedDescription)"
                self.isCapturing = false
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to process captured image"
                self.isCapturing = false
            }
            return
        }
        
        // Mirror the image for selfie (since front camera is mirrored)
        let mirroredImage = image.withHorizontallyFlippedOrientation()
        
        DispatchQueue.main.async {
            self.capturedImage = mirroredImage
            self.isCapturing = false
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Perform face detection on video frames
        detectFaces(in: sampleBuffer)
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func withHorizontallyFlippedOrientation() -> UIImage {
        guard let cgImage = self.cgImage else { return self }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .leftMirrored)
    }
}

