import SwiftUI

struct ContactsScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = ContactsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    ZStack {
                        MiltonLogoView(size: .small)
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(AppTheme.accent)
                                Text("Contacts")
                                    .font(.title2.bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Crisis Resources
                    CrisisResourceCard()
                        .padding(.horizontal)

                    // Company Contacts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Milton Alumni")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)

                        ForEach(viewModel.companyContacts) { contact in
                            Button {
                                viewModel.callNumber(contact.phoneNumber)
                            } label: {
                                HStack {
                                    Image(systemName: "building.2.fill")
                                        .foregroundStyle(AppTheme.accent)
                                        .frame(width: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contact.name)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(AppTheme.textPrimary)
                                        if let role = contact.role {
                                            Text(role)
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(AppTheme.accent)
                                }
                                .padding()
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSmall))
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Sponsor
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("My Sponsor")
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Button {
                                if viewModel.isEditingSponsor {
                                    // Persist to UserDefaults — without this, edits were
                                    // lost when the user navigated away.
                                    viewModel.saveSponsor()
                                } else {
                                    viewModel.isEditingSponsor = true
                                }
                            } label: {
                                Text(viewModel.isEditingSponsor ? "Save" : "Edit")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }

                        if viewModel.isEditingSponsor {
                            VStack(spacing: 12) {
                                TextField("Sponsor name", text: $viewModel.sponsorName)
                                    .textFieldStyle(.roundedBorder)
                                TextField("Phone number", text: $viewModel.sponsorPhone)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.phonePad)
                            }
                            .padding()
                            .cardStyle()
                        } else if !viewModel.sponsorName.isEmpty {
                            Button {
                                viewModel.callNumber(viewModel.sponsorPhone)
                            } label: {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(AppTheme.accent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(viewModel.sponsorName)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(AppTheme.textPrimary)
                                        Text(viewModel.sponsorPhone)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(AppTheme.accent)
                                }
                                .padding()
                                .cardStyle()
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "person.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
                                Text("No sponsor added yet")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Button("Add Sponsor") {
                                    viewModel.isEditingSponsor = true
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.accent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .cardStyle()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top)
            }
            .background(AppTheme.background)
        }
    }
}
