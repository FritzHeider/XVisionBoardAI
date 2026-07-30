import SwiftUI

// MARK: - SignUpView

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserManager.self) var userManager

    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreeToTerms = false
    @State private var showingError = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isFormValid: Bool {
        !email.isEmpty &&
        !username.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreeToTerms
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.astralBlack.ignoresSafeArea()

                // Ambient glow
                Ellipse()
                    .fill(Color.astralViolet.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 60, y: -200)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AstralTheme.Spacing.xl) {
                        // Header
                        VStack(spacing: AstralTheme.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.auroraGradient)
                                    .frame(width: 80, height: 80)
                                    .opacity(0.18)
                                    .blur(radius: 16)

                                Circle()
                                    .strokeBorder(Color.auroraGradient, lineWidth: 1.5)
                                    .frame(width: 72, height: 72)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundStyle(Color.auroraGradient)
                            }
                            .astralPulsing()

                            VStack(spacing: AstralTheme.Spacing.xs) {
                                Text("Join ManifestMe")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.auroraGradient)

                                Text("Start seeing yourself living your dreams")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Color.astralTextMuted)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, AstralTheme.Spacing.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.1), value: appeared)

                        // Form
                        VStack(spacing: AstralTheme.Spacing.md) {
                            AstralTextField(title: "Email", text: $email, keyboardType: .emailAddress)
                            AstralTextField(title: "Username", text: $username)
                            AstralTextField(title: "Password", text: $password, isSecure: true)
                            AstralTextField(title: "Confirm Password", text: $confirmPassword, isSecure: true)

                            // Terms.
                            //
                            // The checkbox and the two legal links have separate
                            // hit areas: previously the whole row was one
                            // toggle button, so the "Terms of Service and
                            // Privacy Policy" text was not actually reachable.
                            // Guideline 5.1.1(i) expects the policy to be
                            // openable from inside the app.
                            HStack(alignment: .firstTextBaseline, spacing: AstralTheme.Spacing.sm) {
                                Button {
                                    agreeToTerms.toggle()
                                } label: {
                                    Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                        .foregroundStyle(agreeToTerms ? Color.astralViolet : Color.astralTextDim)
                                        .scaledFont(size: 18, relativeTo: .body)
                                }
                                .accessibilityLabel("I agree to the Terms of Service and Privacy Policy")
                                .accessibilityAddTraits(agreeToTerms ? [.isSelected] : [])

                                Text("I agree to the [Terms of Service](\(AppLinks.termsOfUse.absoluteString)) and [Privacy Policy](\(AppLinks.privacyPolicy.absoluteString))")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(Color.astralTextMuted)
                                    .tint(Color.astralViolet)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                        }
                        .padding(.horizontal, AstralTheme.Spacing.lg)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.2), value: appeared)

                        // CTA
                        VStack(spacing: AstralTheme.Spacing.sm) {
                            Button("Create Account") {
                                Task {
                                    let success = await userManager.signUp(
                                        email: email,
                                        username: username,
                                        password: password
                                    )
                                    if success { dismiss() } else { showingError = true }
                                }
                            }
                            .astralButton(.primary, isEnabled: isFormValid)
                            .frame(maxWidth: .infinity)
                            .disabled(!isFormValid || userManager.isLoading)
                            .padding(.horizontal, AstralTheme.Spacing.lg)

                            if userManager.isLoading {
                                ProgressView()
                                    .tint(Color.astralViolet)
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.3), value: appeared)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.astralTextMuted)
                }
            }
        }
        .onAppear { appeared = true }
        .alert("Sign Up Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(userManager.errorMessage ?? "An error occurred during sign up")
        }
    }
}

// MARK: - SignInView

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserManager.self) var userManager

    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var showingForgotPassword = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isFormValid: Bool { !email.isEmpty && !password.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.astralBlack.ignoresSafeArea()

                Ellipse()
                    .fill(Color.astralIndigo.opacity(0.15))
                    .frame(width: 280, height: 280)
                    .blur(radius: 80)
                    .offset(x: -60, y: -160)
                    .ignoresSafeArea()

                VStack(spacing: AstralTheme.Spacing.xl) {
                    Spacer()

                    // Header
                    VStack(spacing: AstralTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.auroraGradient)
                                .frame(width: 80, height: 80)
                                .opacity(0.18)
                                .blur(radius: 16)

                            Circle()
                                .strokeBorder(Color.auroraGradient, lineWidth: 1.5)
                                .frame(width: 72, height: 72)

                            Image(systemName: "sparkles")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(Color.auroraGradient)
                        }
                        .astralPulsing()

                        VStack(spacing: AstralTheme.Spacing.xs) {
                            Text("Welcome Back")
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.auroraGradient)

                            Text("Continue your manifestation journey")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Color.astralTextMuted)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.1), value: appeared)

                    // Form
                    VStack(spacing: AstralTheme.Spacing.md) {
                        AstralTextField(title: "Email", text: $email, keyboardType: .emailAddress)
                        AstralTextField(title: "Password", text: $password, isSecure: true)
                    }
                    .padding(.horizontal, AstralTheme.Spacing.lg)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.2), value: appeared)

                    // CTA
                    VStack(spacing: AstralTheme.Spacing.sm) {
                        Button("Sign In") {
                            Task {
                                let success = await userManager.signIn(email: email, password: password)
                                if success { dismiss() } else { showingError = true }
                            }
                        }
                        .astralButton(.primary, isEnabled: isFormValid)
                        .frame(maxWidth: .infinity)
                        .disabled(!isFormValid || userManager.isLoading)
                        .padding(.horizontal, AstralTheme.Spacing.lg)

                        if userManager.isLoading {
                            ProgressView().tint(Color.astralViolet)
                        }

                        // Accounts and boards live only on this device — there is
                        // no server holding a password to reset. Saying so is
                        // both accurate and more useful than the previous
                        // "reset is coming soon" copy, which described a feature
                        // this architecture will never need.
                        Button("Trouble signing in?") { showingForgotPassword = true }
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.astralViolet)
                            .alert("Trouble signing in?", isPresented: $showingForgotPassword) {
                                Button("OK", role: .cancel) {}
                            } message: {
                                Text("ManifestMe keeps your account and boards on this device, so there's no password to recover. Sign in with the email you used here, or create a new account. Need a hand? Email \(AppLinks.supportEmail).")
                            }
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.3), value: appeared)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.astralTextMuted)
                }
            }
        }
        .onAppear { appeared = true }
        .alert("Sign In Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(userManager.errorMessage ?? "Invalid email or password")
        }
    }
}

// MARK: - AstralTextField

struct AstralTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.xs) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.astralTextMuted)
                .textCase(.uppercase)
                .kerning(0.5)

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
            .padding(AstralTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                    .fill(Color.astralSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                            .strokeBorder(
                                text.isEmpty ? Color.astralSurface2 : Color.astralViolet.opacity(0.5),
                                lineWidth: 1
                            )
                    }
            }
            .foregroundStyle(Color.astralText)
            .tint(Color.astralViolet)
        }
    }
}

// Backward compat alias
typealias CustomTextField = AstralTextField

#Preview("Sign Up") {
    SignUpView().environment(UserManager())
}

#Preview("Sign In") {
    SignInView().environment(UserManager())
}
