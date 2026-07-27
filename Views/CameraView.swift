//
//  CameraView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool

    /// Every other animated surface in the app honours Reduce Motion; the live
    /// camera preview was the one screen that did not, and its face-guide pulses
    /// on every frame update — the worst case for vestibular sensitivity.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingImagePicker = false
    @State private var showingPermissionAlert = false
    
var body: some View {
        ZStack {
            Color.cosmicBlack.ignoresSafeArea()
            
            if cameraManager.isAuthorized {
                cameraPreviewView
            } else {
                permissionView
            }
            
            VStack {
                topControls
                Spacer()
                bottomControls
            }
            .padding()
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.teardown()
        }
        .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {
                isPresented = false
            }
        } message: {
            Text("Please enable camera access in Settings to take selfies for your personalized vision boards.")
        }
        .alert("Camera Error", isPresented: Binding(
            get: { cameraManager.errorMessage != nil },
            set: { if !$0 { cameraManager.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
            Button("Choose from Photos") { showingImagePicker = true }
        } message: {
            Text(cameraManager.errorMessage ?? "")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $capturedImage) {
                isPresented = false
            }
        }
        .onChange(of: cameraManager.capturedImage) { _, newImage in
            if let image = newImage {
                capturedImage = image
                isPresented = false
            }
        }
        .onChange(of: cameraManager.permissionDenied) { _, denied in
            if denied {
                showingPermissionAlert = true
            }
        }
    }
    
    // MARK: - Camera Preview
    
    private var cameraPreviewView: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                CameraPreview(session: cameraManager.session)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // Face detection overlay
                faceDetectionOverlay
                    .frame(width: geometry.size.width, height: geometry.size.height)

                if cameraManager.isInterrupted {
                    VStack(spacing: 12) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 44))
                        Text("Camera paused")
                            .font(.headline)
                    }
                    .foregroundStyle(Color.astralText)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.black.opacity(0.7))
                }
            }
        }
    }
    
    private var faceDetectionOverlay: some View {
        ZStack {
            // Face guide circle
            Circle()
                .stroke(
                    cameraManager.faceQuality.color,
                    lineWidth: 4
                )
                .frame(width: 200, height: 200)
                .scaleEffect(cameraManager.faceDetected ? 1.0 : 1.1)
                .opacity(cameraManager.faceDetected ? 1.0 : 0.6)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: cameraManager.faceDetected)
            
            // Quality indicator
            VStack {
                Spacer()
                
                Text(cameraManager.faceQuality.description)
                    .font(.headline)
                    .foregroundStyle(cameraManager.faceQuality.color)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                    )
                    .padding(.bottom, 120)
            }
        }
    }
    
    // MARK: - Permission View
    
    private var permissionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.astralViolet)
                .pulsing()
            
            VStack(spacing: 16) {
                Text("Camera Access Required")
                    .manifestationTitle()
                
                Text("To create personalized vision boards with your face, we need access to your camera.")
                    .manifestationBody()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Enable Camera") {
                // A previously-denied permission can only be changed in Settings
                if AVCaptureDevice.authorizationStatus(for: .video) == .denied ||
                   AVCaptureDevice.authorizationStatus(for: .video) == .restricted {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                } else {
                    cameraManager.checkPermissions()
                }
            }
            .cosmicButton()
            
            Button("Choose from Photos") {
                showingImagePicker = true
            }
            .cosmicButton()
        }
        .padding()
    }
    
    // MARK: - Controls
    
    private var topControls: some View {
        HStack {
            Button("Cancel") {
                isPresented = false
            }
            .foregroundStyle(Color.astralText)
            .padding()
            
            Spacer()
            
            if cameraManager.isAuthorized {
                Button("Photos") {
                    showingImagePicker = true
                }
                .foregroundStyle(Color.astralText)
                .padding()
            }
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Capture tips
            if cameraManager.isAuthorized {
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        Label("Look directly at camera", systemImage: "eye.fill")
                        Label("Good lighting", systemImage: "sun.max.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.astralText.opacity(0.8))
                    
                    HStack(spacing: 16) {
                        Label("Center your face", systemImage: "target")
                        Label("Smile naturally", systemImage: "face.smiling.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.astralText.opacity(0.8))
                }
                .padding(.bottom, 8)
            }
            
            // Capture button
            if cameraManager.isAuthorized {
                Button(action: {
                    cameraManager.capturePhoto()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .stroke(Color.cosmicPurple, lineWidth: 4)
                            .frame(width: 90, height: 90)
                        
                        if cameraManager.isCapturing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.astralViolet)
                        }
                    }
                }
                .disabled(cameraManager.isCapturing || cameraManager.faceQuality == .poor)
                .scaleEffect(cameraManager.faceQuality == .excellent ? 1.1 : 1.0)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: cameraManager.faceQuality)
                .accessibilityLabel("Take photo")
                .accessibilityHint(cameraManager.faceQuality.description)
            }
        }
    }
}

// MARK: - Camera Preview UIViewRepresentable

/// Backing view that keeps the preview layer sized to its bounds through
/// layout passes — a layer frame set at construction time would be zero.
final class CameraPreviewUIView: UIView {
    let previewLayer: AVCaptureVideoPreviewLayer

    init(session: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        CameraPreviewUIView(session: session)
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onImageSelected: () -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.onImageSelected()
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    CameraView(
        capturedImage: .constant(nil),
        isPresented: .constant(true)
    )
}

