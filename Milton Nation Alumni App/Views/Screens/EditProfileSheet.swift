import SwiftUI
import Supabase

/// Lets a member correct their own name and change their phone number.
///
/// Name saves directly. Phone does NOT — the phone is where the login OTP is
/// delivered, so changing it requires proving control of the NEW number first.
/// That runs through the `change-phone` Edge Function (send code → confirm),
/// and a database trigger refuses any phone write that doesn't come from it.
struct EditProfileSheet: View {
    let user: User
    /// Called with the updated user once anything is saved, so the caller can
    /// refresh its copy.
    var onSaved: (User) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel

    @State private var fullName = ""
    @State private var isSavingName = false
    @State private var nameError: String?
    @State private var nameSaved = false

    // Phone change
    private enum PhoneStep { case idle, codeSent }
    @State private var phoneStep: PhoneStep = .idle
    @State private var newPhone = ""
    @State private var smsCode = ""
    @State private var phoneBusy = false
    @State private var phoneError: String?
    @State private var phoneNotice: String?

    private var trimmedName: String {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSaveName: Bool {
        !trimmedName.isEmpty && trimmedName != user.fullName && !isSavingName
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                phoneSection
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { fullName = user.fullName }
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        Section {
            TextField("Full name", text: $fullName)
                .textContentType(.name)
                .autocorrectionDisabled()

            Button {
                Task { await saveName() }
            } label: {
                HStack {
                    if isSavingName { ProgressView().controlSize(.small) }
                    Text(nameSaved ? "Saved" : "Save name")
                }
            }
            .disabled(!canSaveName)

            if let nameError {
                Text(nameError).font(.caption).foregroundStyle(.red)
            }
        } header: {
            Text("Name")
        } footer: {
            Text("This is the name other members see on your posts and comments.")
        }
    }

    private func saveName() async {
        guard canSaveName else { return }
        isSavingName = true
        nameError = nil
        defer { isSavingName = false }

        var updated = user
        updated.fullName = trimmedName
        do {
            let saved = try await appViewModel.dataService.updateProfile(user: updated)
            appViewModel.currentUser = saved
            onSaved(saved)
            nameSaved = true
            AuditLogger.shared.log(.updateProfile, userId: user.id)
        } catch {
            CrashReportingService.shared.recordError(error, context: "EditProfileSheet.saveName")
            nameError = "Could not save your name. Please try again."
        }
    }

    // MARK: - Phone

    private var phoneSection: some View {
        Section {
            LabeledContent("Current", value: maskedCurrentPhone)

            switch phoneStep {
            case .idle:
                TextField("New mobile number", text: $newPhone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)

                Button {
                    Task { await startPhoneChange() }
                } label: {
                    HStack {
                        if phoneBusy { ProgressView().controlSize(.small) }
                        Text("Send verification code")
                    }
                }
                .disabled(newPhone.trimmingCharacters(in: .whitespaces).count < 10 || phoneBusy)

            case .codeSent:
                TextField("6-digit code", text: $smsCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)

                Button {
                    Task { await confirmPhoneChange() }
                } label: {
                    HStack {
                        if phoneBusy { ProgressView().controlSize(.small) }
                        Text("Confirm new number")
                    }
                }
                .disabled(smsCode.count != 6 || phoneBusy)

                Button("Use a different number") {
                    phoneStep = .idle
                    smsCode = ""
                    phoneError = nil
                    phoneNotice = nil
                }
                .font(.footnote)
            }

            if let phoneNotice {
                Text(phoneNotice).font(.caption).foregroundStyle(AppTheme.accent)
            }
            if let phoneError {
                Text(phoneError).font(.caption).foregroundStyle(.red)
            }
        } header: {
            Text("Phone Number")
        } footer: {
            Text("You sign in with a code sent by text, so we have to confirm a new number before switching to it.")
        }
    }

    private var maskedCurrentPhone: String {
        let digits = user.phone.filter(\.isNumber)
        guard digits.count >= 4 else { return user.phone.isEmpty ? "Not set" : user.phone }
        return "••• ••• " + digits.suffix(4)
    }

    private func startPhoneChange() async {
        phoneBusy = true
        phoneError = nil
        phoneNotice = nil
        defer { phoneBusy = false }

        do {
            let response: ChangePhoneResponse = try await SupabaseConfig.client.functions.invoke(
                "change-phone",
                options: .init(method: .post, body: [
                    "action": "start",
                    "newPhone": newPhone.trimmingCharacters(in: .whitespaces)
                ])
            )
            if let error = response.error {
                phoneError = error
            } else {
                phoneStep = .codeSent
                phoneNotice = "Code sent to \(response.phone ?? "your new number")."
            }
        } catch {
            CrashReportingService.shared.recordError(error, context: "EditProfileSheet.startPhoneChange")
            phoneError = "Could not send the code. Check the number and try again."
        }
    }

    private func confirmPhoneChange() async {
        phoneBusy = true
        phoneError = nil
        defer { phoneBusy = false }

        do {
            let response: ChangePhoneResponse = try await SupabaseConfig.client.functions.invoke(
                "change-phone",
                options: .init(method: .post, body: [
                    "action": "confirm",
                    "newPhone": newPhone.trimmingCharacters(in: .whitespaces),
                    "code": smsCode
                ])
            )
            if let error = response.error {
                phoneError = error
                return
            }
            guard response.changed == true, let saved = response.phone else {
                phoneError = "Could not confirm that code."
                return
            }

            var updated = appViewModel.currentUser ?? user
            updated.phone = saved
            appViewModel.currentUser = updated
            onSaved(updated)

            phoneStep = .idle
            smsCode = ""
            newPhone = ""
            phoneNotice = "Phone number updated. Your next sign-in code goes to the new number."
        } catch {
            CrashReportingService.shared.recordError(error, context: "EditProfileSheet.confirmPhoneChange")
            phoneError = "Could not confirm that code. Please try again."
        }
    }
}

/// Shape of every `change-phone` response. All fields optional because the
/// function returns different keys per step and per failure mode.
private struct ChangePhoneResponse: Decodable {
    let sent: Bool?
    let changed: Bool?
    let phone: String?
    let error: String?
}
