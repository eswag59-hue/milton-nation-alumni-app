import SwiftUI

struct StrugglingButton: View {
    @Binding var showModal: Bool

    var body: some View {
        Button {
            showModal = true
        } label: {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(AppTheme.struggling)
                Text("I'm struggling today")
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.strugglingLight)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
        .accessibilityLabel("I'm struggling today")
        .accessibilityHint("Double tap to access crisis resources and care team contacts")
    }
}
