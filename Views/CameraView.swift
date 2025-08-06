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
    
    @State private var showingImagePicker = false
    @State private var showingPermissionAlert = false
    
    /Users/space/XVisionBoardAI/XVisionBoardAI/XVisionBoardAIApp.swiftvar body: some View {
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
            cameraManager.stopSession()
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
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $capturedImage) {
                isPresented = false
            }
        }
        .onChange(of: cameraManager.capturedImage) { newImage in
            if let image = newImage {
                capturedImage = image
                isPresented = false
            }
        }
        .onChange(of: cameraManager.errorMessage) { errorMessage in
            if errorMessage != nil {
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
                .animation(.easeInOut(duration: 0.3), value: cameraManager.faceDetected)
            
            // Quality indicator
            VStack {
                Spacer()
                
                Text(cameraManager.faceQuality.description)
                    .font(.headline)
                    .foregroundColor(cameraManager.faceQuality.color)
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
                .foregroundColor(.cosmicPurple)
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
                cameraManager.checkPermissions()
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
            .foregroundColor(.cosmicWhite)
            .padding()
            
            Spacer()
            
            if cameraManager.isAuthorized {
                Button("Photos") {
                    showingImagePicker = true
                }
                .foregroundColor(.cosmicWhite)
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
                    .foregroundColor(.cosmicWhite.opacity(0.8))
                    
                    HStack(spacing: 16) {
                        Label("Center your face", systemImage: "target")
                        Label("Smile naturally", systemImage: "face.smiling.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.cosmicWhite.opacity(0.8))
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
                                .progressViewStyle(CircularProgressViewStyle(tint: .cosmicPurple))
                        }
                    }
                }
                .disabled(cameraManager.isCapturing || cameraManager.faceQuality == .poor)
                .scaleEffect(cameraManager.faceQuality == .excellent ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: cameraManager.faceQuality)
            }
        }
    }
}

// MARK: - Camera Preview UIViewRepresentable

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
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

