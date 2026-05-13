import SwiftUI

struct HomeScreen: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = HomeViewModel()

    var body: some View {
        @Bindable var appViewModel = appViewModel
        return NavigationStack {
            VStack(spacing: 0) {
                PageHeader()

                ScrollView {
                    VStack(spacing: 16) {
                        // Welcome
                        if let user = appViewModel.currentUser {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back, \(user.firstName.lowercased())")
                                    .font(.title2.bold())
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text("Your recovery journey continues today")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.accent)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 12)

                            SobrietyTrackerCard(user: user, onUpdateRecoveryDate: {
                                appViewModel.showSobrietyCheck = true
                            })
                                .padding(.horizontal)
                        }

                    DailyReflectionCard(quote: viewModel.dailyQuote)
                        .padding(.horizontal)

                    // Points & Badges box
                    if let user = appViewModel.currentUser {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "star.circle.fill")
                                    .foregroundStyle(AppTheme.accentLime)
                                Text("Points & Badges")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()
                                Text("\(user.totalPoints) pts")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.accent)
                            }
                            Text("Earn points by logging in daily, posting, and hitting milestones!")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding()
                        .cardStyle()
                        .padding(.horizontal)
                    }

                    AnnouncementCard(announcements: viewModel.announcements)
                        .padding(.horizontal)

                    StrugglingButton(showModal: $viewModel.showStrugglingModal)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
            .background(AppTheme.background)
            .sheet(isPresented: $viewModel.showStrugglingModal) {
                StrugglingModal()
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
}
