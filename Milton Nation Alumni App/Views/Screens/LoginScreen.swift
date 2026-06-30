import SwiftUI
import LocalAuthentication

struct LoginScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel: LoginViewModel
    @State private var showResendConfirmation = false

    private enum LoginField: Hashable { case email, password, twoFactor }
    @FocusState private var focusedField: LoginField?

    /// Pass the auth service at construction time so the ViewModel is wired
    /// correctly on the very first render — no async task injection required.
    init(authService: AuthServiceProtocol) {
        _viewModel = State(initialValue: LoginViewModel(authService: authService))
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo & Branding
                        VStack(spacing: 0) {
                            MiltonLogoView(size: .splash)

                            Text("Driven by purpose. Committed to care.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(AppTheme.textSecondary)
                                .tracking(0.4)
                                .multilineTextAlignment(.center)
                                .padding(.top, 20)

                            Rectangle()
                                .fill(AppTheme.textSecondary.opacity(0.15))
                                .frame(width: 48, height: 1)
                                .padding(.top, 24)
                        }
                        .padding(.top, 48)
                        .padding(.bottom, 16)

                        if viewModel.showTwoFactor {
                            twoFactorView
                                .id(LoginField.twoFactor)
                        } else if viewModel.isRegistering {
                            registrationForm
                        } else {
                            loginForm
                                .id(LoginField.email)
                        }

                        // Bottom spacer ensures focused field can scroll above keyboard
                        Color.clear.frame(height: 200)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .background(AppTheme.background)
                .onChange(of: focusedField) { _, newField in
                    // Auto-scroll the focused field above the keyboard so the user
                    // can always see what they're typing. iOS does this poorly when
                    // the form is short and the keyboard takes 50%+ of the screen.
                    guard let newField else { return }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newField, anchor: .center)
                    }
                }
                .onAppear {
                    // Auto-focus email field so users can type immediately on the simulator
                    // without needing to tap the field first.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        focusedField = .email
                    }
                }
                .onChange(of: viewModel.showTwoFactor) {
                    if viewModel.showTwoFactor { focusedField = .twoFactor }
                    else { focusedField = .email }
                }
                .onChange(of: viewModel.isRegistering) {
                    if viewModel.isRegistering { focusedField = .email }
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
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .password }
                    .submitLabel(.next)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(focusedField == .email ? AppTheme.accent : AppTheme.divider, lineWidth: focusedField == .email ? 2 : 1)
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
                    .focused($focusedField, equals: .password)
                    .onSubmit { Task { _ = await viewModel.login() } }
                    .submitLabel(.go)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(focusedField == .password ? AppTheme.accent : AppTheme.divider, lineWidth: focusedField == .password ? 2 : 1)
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
                viewModel.resetEmail = viewModel.email
                viewModel.passwordResetSent = false
                viewModel.errorMessage = nil
                viewModel.showForgotPassword = true
            } label: {
                Text("Forgot password?")
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.accent)

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
        .sheet(isPresented: $viewModel.showForgotPassword) {
            forgotPasswordSheet
        }
    }

    // MARK: - Forgot Password Sheet

    @ViewBuilder
    private var forgotPasswordSheet: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.top, 8)

                if viewModel.passwordResetSent {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(AppTheme.accentSage)
                        Text("Reset Email Sent")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Check your inbox for a password reset link. It may take a minute to arrive.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reset Your Password")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Enter the email address associated with your account and we'll send you a link to reset your password.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(AppTheme.struggling)
                                .padding(.vertical, 6)
                        }

                        TextField("Email address", text: $viewModel.resetEmail)
                            .textFieldStyle(.plain)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                    .stroke(AppTheme.divider, lineWidth: 1)
                            )

                        Button {
                            Task { await viewModel.sendPasswordReset() }
                        } label: {
                            HStack {
                                if viewModel.isResettingPassword { ProgressView().tint(.white) }
                                Text("Send Reset Link").font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.accent)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                        .disabled(viewModel.isResettingPassword)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .background(AppTheme.background)
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { viewModel.showForgotPassword = false }
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
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
                .focused($focusedField, equals: .twoFactor)
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

            Text("By providing your phone number, you consent to receive a one-time verification code via SMS. Message & data rates may apply.")
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 4)

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

            // Facility picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Facility")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                HStack(spacing: 12) {
                    ForEach(Facility.allCases) { facility in
                        let isSelected = viewModel.regFacility == facility
                        Button {
                            viewModel.regFacility = facility
                        } label: {
                            VStack(spacing: 4) {
                                Text(facility.emoji)
                                    .font(.title2)
                                Text(facility.displayName)
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
                            .background(isSelected ? AppTheme.accent : AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall)
                                    .stroke(isSelected ? AppTheme.accent : AppTheme.divider, lineWidth: isSelected ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text("Select the Milton Recovery Center you attended.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            // MARK: - Consent (Apple Guideline 1.2 — required agreement)
            consentRow

            Button {
                Task { _ = await viewModel.register() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text("Register").font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background((viewModel.isLoading || !viewModel.regAgreedToTerms) ? AppTheme.textSecondary : AppTheme.accent)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            // Register stays disabled until the user agrees to Terms + Privacy.
            .disabled(viewModel.isLoading || !viewModel.regAgreedToTerms)

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

    // MARK: - Consent Row (Apple Guideline 1.2)

    /// Required agreement checkbox + tappable Terms / Privacy links. The links
    /// open in Safari via the AttributedString markdown; tapping the checkbox
    /// (or its label) toggles consent without following a link.
    private var consentRow: some View {
        // Markdown links render as tappable and open the live policy pages.
        let agreement: AttributedString = {
            // swiftlint:disable:next line_length
            var s = (try? AttributedString(
                markdown: "I agree to the [Terms of Use](https://miltonrecovery.com/app-terms-of-use/) and [Privacy Policy](https://miltonrecovery.com/milton-nation-privacy/)."
            )) ?? AttributedString("I agree to the Terms of Use and Privacy Policy.")
            s.foregroundColor = AppTheme.textSecondary
            return s
        }()

        return HStack(alignment: .top, spacing: 10) {
            Button {
                viewModel.regAgreedToTerms.toggle()
            } label: {
                Image(systemName: viewModel.regAgreedToTerms ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(viewModel.regAgreedToTerms ? AppTheme.accent : AppTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Agree to Terms of Use and Privacy Policy")
            .accessibilityValue(viewModel.regAgreedToTerms ? "Checked" : "Not checked")
            .accessibilityAddTraits(.isButton)

            // tappable links live inside this Text; opens in Safari via .tint
            Text(agreement)
                .font(.caption)
                .tint(AppTheme.accent)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
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
                    // Try the in-memory cached user first (fast path when app hasn't been killed)
                    if let user = appViewModel.authService.getCurrentUser() {
                        appViewModel.login(user: user)
                        return
                    }
                    // App was relaunched — restore session from Supabase using stored JWT
                    if let supabaseAuth = appViewModel.authService as? SupabaseAuthService,
                       let user = await supabaseAuth.restoreSession() {
                        appViewModel.login(user: user)
                    } else {
                        // Session fully expired — require full MFA login again
                        viewModel.errorMessage = "Your session has expired. Please log in with your email and password."
                        KeychainService.delete(key: .mfaCompleted)
                    }
                } else {
                    viewModel.errorMessage = error?.localizedDescription ?? "Face ID authentication failed. Please use your password."
                }
            }
        }
    }
}
