import SwiftUI

struct EditJourneySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int
    @State private var isSaving = false
    @State private var saveError: String? = nil

    private let calendar = Calendar.current
    private let monthNames = Calendar.current.monthSymbols
    private let currentYear: Int
    private let currentMonth: Int
    private let currentDay: Int

    init(user: User) {
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month, .day], from: user.sobrietyDate)
        let todayComponents = cal.dateComponents([.year, .month, .day], from: Date())
        self._selectedYear = State(initialValue: components.year ?? 2024)
        self._selectedMonth = State(initialValue: components.month ?? 1)
        self._selectedDay = State(initialValue: components.day ?? 1)
        self.currentYear = todayComponents.year ?? 2026
        self.currentMonth = todayComponents.month ?? 1
        self.currentDay = todayComponents.day ?? 1
    }

    /// Number of days in the currently selected month/year
    private var daysInMonth: Int {
        let comps = DateComponents(year: selectedYear, month: selectedMonth)
        guard let date = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 31
        }
        return range.count
    }

    /// Available years (1950 → current year)
    private var yearRange: [Int] {
        Array((1950...currentYear).reversed())
    }

    /// Available months — clamped to current month if selected year is current year
    private var monthRange: ClosedRange<Int> {
        if selectedYear == currentYear {
            return 1...currentMonth
        }
        return 1...12
    }

    /// Available days — clamped to current day if year+month is current
    private var dayRange: ClosedRange<Int> {
        let maxDay: Int
        if selectedYear == currentYear && selectedMonth == currentMonth {
            maxDay = min(daysInMonth, currentDay)
        } else {
            maxDay = daysInMonth
        }
        return 1...maxDay
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Sobriety Date
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sobriety Date")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("When did your current recovery journey begin?")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)

                        // Custom 3-column picker
                        HStack(spacing: 0) {
                            // Month picker
                            Picker("Month", selection: $selectedMonth) {
                                ForEach(monthRange, id: \.self) { month in
                                    Text(monthNames[month - 1])
                                        .tag(month)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(maxWidth: .infinity)
                            .clipped()

                            // Day picker
                            Picker("Day", selection: $selectedDay) {
                                ForEach(dayRange, id: \.self) { day in
                                    Text("\(day)")
                                        .tag(day)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()

                            // Year picker
                            Picker("Year", selection: $selectedYear) {
                                ForEach(yearRange, id: \.self) { year in
                                    Text(String(year))
                                        .tag(year)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 90)
                            .clipped()
                        }
                        .frame(height: 150)
                        .onChange(of: selectedYear) { clampSelections() }
                        .onChange(of: selectedMonth) { clampSelections() }

                        // Preview of selected date
                        if let date = constructDate() {
                            Text(date.formatted(date: .long, time: .omitted))
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.accent)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .cardStyle()
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Edit Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveChanges()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .bold()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .alert("Save Failed", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    /// Clamp month and day to valid ranges when year or month changes
    private func clampSelections() {
        // Clamp month if current year selected
        if selectedYear == currentYear && selectedMonth > currentMonth {
            selectedMonth = currentMonth
        }
        // Clamp day to valid range
        let maxDay = dayRange.upperBound
        if selectedDay > maxDay {
            selectedDay = maxDay
        }
    }

    /// Construct a Date from the 3 selected components
    private func constructDate() -> Date? {
        let comps = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
        return calendar.date(from: comps)
    }

    private func saveChanges() {
        guard var user = appViewModel.currentUser,
              let newDate = constructDate() else { return }
        isSaving = true
        user.sobrietyDate = newDate
        user.updatedAt = Date()

        Task {
            do {
                _ = try await appViewModel.dataService.updateProfile(user: user)
                await MainActor.run {
                    appViewModel.currentUser = user
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = "Failed to save. Please try again."
                }
            }
        }
    }
}
