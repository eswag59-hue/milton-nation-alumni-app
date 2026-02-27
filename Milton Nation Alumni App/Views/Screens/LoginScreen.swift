import SwiftUI
import LocalAuthentication

struct LoginScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = LoginViewModel()
    @State private var authServiceInjected = false
    @State private var showResendConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo & Branding
                    VStack(spacing: 12) {
                        MiltonLogoView(size: .extraLarge)

                        // App name
                        Text("Milton Alumni")
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.top, 16)

                        // Tagline
                        Text("Driven by purpose. Committed to care.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 8)

                    if viewModel.showTwoFactor {
                        twoFactorView
                    } else if viewModel.isRegistering {
                        registrationForm
                    } else {
                        loginForm
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .task {
                if !authServiceInjected {
                    authServiceInjected = true
                    viewModel = LoginViewModel(authService: appViewModel.authService)
                }
            }
            .alert("Registration Submitted", isPresented: $viewModel.showRegistrationSuccess) {
                Button("OK") {
                    viewModel.isRegistering = false
                    viewModel.resetForm()
                }
            } message: {
                Text("Your account is pending approval. You'll receive an email once activated.")
            }
        }
    }

    // MARK: - Login Form

    private var loginForm: some View {
        VStack(spacing: 16) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppTheme.struggling)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.strugglingLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Email
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                TextField("Enter your email", text: $viewModel.email)
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppTheme.textPrimary)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(AppTheme.divider, lineWidth: 1)
                    )
            }

            // Password
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                SecureField("Enter your password", text: $viewModel.password)
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppTheme.textPrimary)
                    .textContentType(.password)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(AppTheme.divider, lineWidth: 1)
                    )
            }

            // Login button
            Button {
                Task { _ = await viewModel.login() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text("Login").font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(viewModel.isLockedOut ? AppTheme.textSecondary : AppTheme.accent)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .disabled(viewModel.isLoading || viewModel.isLockedOut)
            .accessibilityLabel("Login")
            .accessibilityHint("Double tap to sign in to your account")

            // Only show Face ID if user previously completed MFA
            if hasPreviouslyCompletedMFA {
                Button {
                    authenticateWithBiometrics()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "faceid")
                            .font(.title3)
                        Text("Sign in with Face ID")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(AppTheme.accent)
                    .background(
                        Capsule()
                            .stroke(AppTheme.accent, lineWidth: 1.5)
                    )
                }
                .disabled(viewModel.isLockedOut)
                .accessibilityLabel("Sign in with Face ID")
            }

            Button {
                viewModel.errorMessage = nil
                viewModel.isRegistering = true
            } label: {
                Text("Don't have an account? \(Text("Register").bold())")
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.accent)
            .accessibilityLabel("Register for a new account")
        }
        .padding()
        .cardStyle()
        .padding(.horizontal, 4)
    }

    // MARK: - Two-Factor View

    private var twoFactorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.accent)

            Text("Two-Factor Authentication")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Enter the 6-digit code sent to your phone via SMS.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppTheme.struggling)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.strugglingLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            TextField("000000", text: $viewModel.twoFactorCode)
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.textPrimary)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title2.monospaced())
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                        .fill(AppTheme.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                        .stroke(AppTheme.divider, lineWidth: 1)
                )
                .onChange(of: viewModel.twoFactorCode) {
                    let filtered = viewModel.twoFactorCode.filter(\.isNumber)
                    if filtered.count > 6 {
                        viewModel.twoFactorCode = String(filtered.prefix(6))
                    } else {
                        viewModel.twoFactorCode = filtered
                    }
                }

            Button {
                Task {
                    if let user = await viewModel.verifyTwoFactor() {
                        // Save MFA completion so biometric can be used next time
                        KeychainService.save(key: .mfaCompleted, string: "true")
                        await MainActor.run { appViewModel.login(user: user) }
                    }
                }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text("Verify").font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(viewModel.twoFactorCode.count == 6 ? AppTheme.accent : AppTheme.textSecondary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .disabled(viewModel.twoFactorCode.count != 6 || viewModel.isLoading)

            Button {
                viewModel.twoFactorCode = ""
                showResendConfirmation = true
                Task {
                    await viewModel.resendSMSOTP()
                    try? await Task.sleep(for: .seconds(2))
                    showResendConfirmation = false
                }
            } label: {
                if showResendConfirmation {
                    Text("Code Resent!")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.accentSage)
                } else {
                    Text("Resend Code")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .disabled(showResendConfirmation)

            Button("Back to Login") {
                viewModel.showTwoFactor = false
                viewModel.twoFactorCode = ""
                viewModel.errorMessage = nil
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .cardStyle()
        .padding(.horizontal, 4)
    }

    // MARK: - Registration Form

    private var registrationForm: some View {
        VStack(spacing: 16) {
            Text("Create Account")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppTheme.struggling)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.strugglingLight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            formField("Full Name", text: $viewModel.regFullName, contentType: .name)

            // Username
            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                TextField("Choose a unique username", text: $viewModel.regUsername)
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppTheme.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                            .fill(AppTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                            .stroke(AppTheme.divider, lineWidth: 1)
                    )
                Text("This will be shown on community posts. Cannot contain your real name.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            formField("Email", text: $viewModel.regEmail, contentType: .emailAddress, keyboard: .emailAddress)
            formField("Phone", text: $viewModel.regPhone, contentType: .telephoneNumber, keyboard: .phonePad)

            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                SecureField("At least 8 characters", text: $viewModel.regPassword)
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppTheme.textPrimary)
                    .textContentType(.newPassword)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                            .fill(AppTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                            .stroke(AppTheme.divider, lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Confirm Password")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                SecureField("Re-enter password", text: $viewModel.regConfirmPassword)
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppTheme.textPrimary)
                    .textContentType(.newPassword)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                            .fill(AppTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                            .stroke(AppTheme.divider, lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Sobriety Date")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                DatePicker("", selection: $viewModel.regSobrietyDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Discharge Date")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                DatePicker("", selection: $viewModel.regDischargeDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

            // Recovery Program dropdown
            VStack(alignment: .leading, spacing: 6) {
                Text("Recovery Program")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Menu {
                    ForEach(RecoveryProgram.allCases) { program in
                        Button(program.displayName) {
                            viewModel.regRecoveryProgram = program
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.regRecoveryProgram.displayName)
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(14)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                            .stroke(AppTheme.divider, lineWidth: 1)
                    )
                }
            }

            Button {
                Task { _ = await viewModel.register() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text("Register").font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.accent)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .disabled(viewModel.isLoading)

            Button {
                viewModel.errorMessage = nil
                viewModel.isRegistering = false
            } label: {
                Text("Already have an account? \(Text("Login").bold())")
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.accent)
        }
        .cardStyle()
        .padding(.horizontal, 4)
    }

    // MARK: - Helpers

    private func formField(_ label: String, text: Binding<String>, contentType: UITextContentType? = nil, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.textPrimary)
            TextField(label, text: text)
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.textPrimary)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                        .fill(AppTheme.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                        .stroke(AppTheme.divider, lineWidth: 1)
                )
        }
    }

    private var hasPreviouslyCompletedMFA: Bool {
        KeychainService.loadString(key: .mfaCompleted) == "true"
    }

    private func authenticateWithBiometrics() {
        guard hasPreviouslyCompletedMFA else {
            viewModel.errorMessage = "Please complete MFA login first before using Face ID."
            return
        }

        let context = LAContext()
        context.localizedCancelTitle = "Use Password"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Sign in to Milton Alumni") { success, error in
            Task { @MainActor in
                if success {
                    appViewModel.login(user: MockData.currentUser)
                } else {
                    viewModel.errorMessage = error?.localizedDescription ?? "Face ID authentication failed. Please use your password."
                }
            }
        }
    }
}
