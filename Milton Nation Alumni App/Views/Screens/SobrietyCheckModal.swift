import SwiftUI

struct SobrietyCheckModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    @State private var showDatePicker = false
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedDay: Int = Calendar.current.component(.day, from: Date())
    @State private var showResetConfirmation = false

    private let calendar = Calendar.current
    private let monthNames = Calendar.current.monthSymbols
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let currentMonth = Calendar.current.component(.month, from: Date())
    private let currentDay = Calendar.current.component(.day, from: Date())

    /// Number of days in the selected month/year
    private var daysInMonth: Int {
        let comps = DateComponents(year: selectedYear, month: selectedMonth)
        guard let date = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 31
        }
        return range.count
    }

    /// Available years (1950 → current year), newest first
    private var yearRange: [Int] {
        Array((1950...currentYear).reversed())
    }

    /// Available months — clamped if selected year is current year
    private var monthRange: ClosedRange<Int> {
        if selectedYear == currentYear {
            return 1...currentMonth
        }
        return 1...12
    }

    /// Available days — clamped if year+month is current
    private var dayRange: ClosedRange<Int> {
        let maxDay: Int
        if selectedYear == currentYear && selectedMonth == currentMonth {
            maxDay = min(daysInMonth, currentDay)
        } else {
            maxDay = daysInMonth
        }
        return 1...maxDay
    }

    /// Construct a Date from the 3 selected components
    private func constructDate() -> Date? {
        let comps = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
        return calendar.date(from: comps)
    }

    /// Clamp month and day to valid ranges when year or month changes
    private func clampSelections() {
        if selectedYear == currentYear && selectedMonth > currentMonth {
            selectedMonth = currentMonth
        }
        let maxDay = dayRange.upperBound
        if selectedDay > maxDay {
            selectedDay = maxDay
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(AppTheme.accent)

                    Text("Welcome Back!")
                        .font(.title.bold())
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("We're glad you're here. How are you doing on your journey?")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Still sober question
                VStack(spacing: 8) {
                    Text("Are you still on track?")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    if let user = appViewModel.currentUser {
                        Text("\(user.daysOfRecovery) days of recovery")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.accent)
                    }
                }

                // Date picker (shown after tapping reset)
                if showDatePicker {
                    VStack(spacing: 12) {
                        Text("Select your new sobriety date")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.textPrimary)

                        // 3-column wheel picker
                        HStack(spacing: 0) {
                            // Month
                            Picker("Month", selection: $selectedMonth) {
                                ForEach(monthRange, id: \.self) { month in
                                    Text(monthNames[month - 1])
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .tag(month)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                            .clipped()

                            // Day
                            Picker("Day", selection: $selectedDay) {
                                ForEach(dayRange, id: \.self) { day in
                                    Text("\(day)")
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .tag(day)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()

                            // Year
                            Picker("Year", selection: $selectedYear) {
                                ForEach(yearRange, id: \.self) { year in
                                    Text(String(year))
                                        .foregroundStyle(AppTheme.textPrimary)
                                        .tag(year)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 90)
                            .clipped()
                        }
                        .tint(AppTheme.textPrimary)
                        .frame(height: 150)
                        .onChange(of: selectedYear) { clampSelections() }
                        .onChange(of: selectedMonth) { clampSelections() }

                        // Preview selected date
                        if let date = constructDate() {
                            Text(date.formatted(date: .long, time: .omitted))
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.accent)
                        }

                        // Confirm reset button
                        Button {
                            showResetConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Confirm Reset")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(AppTheme.struggling)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        }

                        Button {
                            withAnimation { showDatePicker = false }
                        } label: {
                            Text("Cancel")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .padding()
                    .cardStyle()
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                // Buttons (hidden when date picker is showing)
                if !showDatePicker {
                    VStack(spacing: 12) {
                        Button {
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Yes, still going strong!")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.white)
                            .background(AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        }
                        .accessibilityLabel("Yes, still going strong")
                        .accessibilityHint("Confirm you are still on track with your recovery")

                        Button {
                            withAnimation { showDatePicker = true }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("I need to reset my date")
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(AppTheme.textSecondary)
                            .background(AppTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        }
                        .accessibilityLabel("Reset sobriety date")
                        .accessibilityHint("Double tap to choose a new sobriety date")

                        Text("There's no shame in starting over. Every day is a new beginning.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .italic()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .background(AppTheme.cardBackground)
            .alert("Reset Sobriety Date?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    if let newDate = constructDate() {
                        appViewModel.resetSobrietyDate(to: newDate)
                    }
                    dismiss()
                }
            } message: {
                if let date = constructDate() {
                    Text("This will set your sobriety date to \(date.formatted(date: .long, time: .omitted)). Your previous progress is still something to be proud of.")
                } else {
                    Text("This will reset your sobriety counter. Your previous progress is still something to be proud of.")
                }
            }
            .interactiveDismissDisabled()
        }
    }
}
