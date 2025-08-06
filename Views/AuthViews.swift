//
//  AuthViews.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreeToTerms = false
    @State private var showingError = false
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !username.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreeToTerms
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "eye.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.cosmicPurple)
                            
                            VStack(spacing: 8) {
                                Text("Join XVisionBoard AI")
                                    .manifestationTitle()
                                
                                Text("Start seeing yourself living your dreams")
                                    .manifestationBody()
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: 20) {
                            CustomTextField(
                                title: "Email",
                                text: $email,
                                keyboardType: .emailAddress
                            )
                            
                            CustomTextField(
                                title: "Username",
                                text: $username
                            )
                            
                            CustomTextField(
                                title: "Password",
                                text: $password,
                                isSecure: true
                            )
                            
                            CustomTextField(
                                title: "Confirm Password",
                                text: $confirmPassword,
                                isSecure: true
                            )
                            
                            // Terms agreement
                            HStack {
                                Button(action: {
                                    agreeToTerms.toggle()
                                }) {
                                    Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                        .foregroundColor(agreeToTerms ? .cosmicPurple : .gray)
                                }
                                
                                Text("I agree to the Terms of Service and Privacy Policy")
                                    .font(.caption)
                                    .foregroundColor(.cosmicWhite.opacity(0.8))
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        
                        // Sign up button
                        Button("Create Account") {
                            Task {
                                let success = await userManager.signUp(
                                    email: email,
                                    username: username,
                                    password: password
                                )
                                if success {
                                    dismiss()
                                } else {
                                    showingError = true
                                }
                            }
                        }
                        .cosmicButton(isEnabled: isFormValid)
                        .disabled(!isFormValid || userManager.isLoading)
                        .padding(.horizontal)
                        
                        if userManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .cosmicPurple))
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.cosmicWhite)
                }
            }
        }
        .alert("Sign Up Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(userManager.errorMessage ?? "An error occurred during sign up")
        }
    }
}

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicBlack.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "eye.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.cosmicPurple)
                        
                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .manifestationTitle()
                            
                            Text("Continue your manifestation journey")
                                .manifestationBody()
                        }
                    }
                    
                    // Form
                    VStack(spacing: 20) {
                        CustomTextField(
                            title: "Email",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        CustomTextField(
                            title: "Password",
                            text: $password,
                            isSecure: true
                        )
                    }
                    .padding(.horizontal)
                    
                    // Sign in button
                    Button("Sign In") {
                        Task {
                            let success = await userManager.signIn(
                                email: email,
                                password: password
                            )
                            if success {
                                dismiss()
                            } else {
                                showingError = true
                            }
                        }
                    }
                    .cosmicButton(isEnabled: isFormValid)
                    .disabled(!isFormValid || userManager.isLoading)
                    .padding(.horizontal)
                    
                    if userManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .cosmicPurple))
                    }
                    
                    // Forgot password
                    Button("Forgot Password?") {
                        // Handle forgot password
                    }
                    .foregroundColor(.cosmicPurple)
                    .font(.subheadline)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.cosmicWhite)
                }
            }
        }
        .alert("Sign In Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(userManager.errorMessage ?? "Invalid email or password")
        }
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.cosmicWhite)
            
            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .keyboardType(keyboardType)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cosmicGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cosmicPurple.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.cosmicWhite)
        }
    }
}

#Preview("Sign Up") {
    SignUpView()
        .environmentObject(UserManager())
}

#Preview("Sign In") {
    SignInView()
        .environmentObject(UserManager())
}

